# === ProductCategory ===
#
# Model reprezentuje kategorię produktów w systemie. Pozwala na:
# - grupowanie produktów w kategorie i podkategorie
# - hierarchiczne drzewo kategorii
# - zarządzanie widocznością i kolejnością wyświetlania
#
# Atrybuty:
# - organization_id:bigint -> multi tenant
# - id_by_org:integer -> unikalny identyfikator produktu w ramach organizacji
# - name:string -> nazwa kategorii
# - description:text -> opis kategorii
# - slug:string -> unikalny, przyjazny URL, np. "elektronika"
# - code:string -> unikalny kod kategorii, np. "ELE", "SMA1"
# - position:integer -> kolejność wyświetlania
# - product_category_id:bigint -> referencja do rodzica dla podkategorii
# - visible:boolean -> czy kategoria jest widoczna dla użytkowników
# - disabled:boolean -> soft-delete, dezaktywacja kategorii
# - main_image:active_storage -> zdjęcia kategorii
# - private_images:active_storage -> zdjęcia robocze

class ProductCategory < ApplicationRecord
  include Tenantable
  include Destroyable
  include Loggable
  include OrganizationScoped

  # === RELACJE ===
  belongs_to :organization
  
  # relacja hierarchiczna
  belongs_to :parent, class_name: "ProductCategory", foreign_key: "product_category_id", optional: true
  has_many :subcategories, class_name: "ProductCategory", foreign_key: "product_category_id", dependent: :destroy
  accepts_nested_attributes_for :subcategories, allow_destroy: true

  # produkty należące do kategorii
  has_many :products, dependent: :destroy
  
  has_many :logs, as: :loggable, dependent: :destroy # historia zmian

  has_one_attached :main_image # główne zdjęcie kategorii
  has_many_attached :private_images # zdjęcia robocze / prywatne

  # === WALIDACJE ===
  validates :name, presence: true
  validates :slug, uniqueness: { scope: :organization_id, allow_blank: true }
  validates :code, uniqueness: { scope: :organization_id }

  # === SCOPE ===
  scope :active, -> { where(disabled: false) } # niezarchiwizowane
  scope :visible, -> { where(visible: true, disabled: false) }

  # === CALLBACKI ===
  before_validation :generate_slug, if: -> { name.present? }
  after_save :generate_code, if: -> { code.blank? }



  # === METODY ===
   
  def self.for_user(user)
    all
  end
  
  def self.icon
    "tags"
  end

  def self.roots
    where(product_category_id: nil)
  end

  def is_root?
    parent.nil?
  end

  def self.leafs
    where.not(id: ProductCategory.select(:product_category_id).distinct)
  end

  def is_leaf?
    subcategories.empty?
  end

  def full_name
    parent ? "#{parent.full_name} > #{name}" : name
  end

  def subtree_ids
    [id] + subcategories.flat_map(&:subtree_ids)
  end

  # Liczy wszystkie zagnieżdżone podkategorie i produkty w jednym zapytaniu (rekurencyjne CTE).
  # Korzysta z prezaładowanych kolumn (with_aggregated_counts) jeśli są dostępne, aby nie odpalać dodatkowego SQL.
  def aggregated_counts
    # Jeśli mamy preloaded columns ze scope'a - użyj ich
    if has_attribute?(:subcategories_count) && has_attribute?(:products_count)
      return {
        subcategories_count: self[:subcategories_count].to_i,
        products_count: self[:products_count].to_i
      }
    end

    # Fallback - wykonaj zapytanie
    @aggregated_counts ||= begin
      sql = <<~SQL
        WITH RECURSIVE category_tree AS (
          SELECT id FROM product_categories WHERE id = ?
          UNION ALL
          SELECT pc.id
          FROM product_categories pc
          JOIN category_tree ct ON pc.product_category_id = ct.id
        )
        SELECT
          COUNT(DISTINCT ct.id) - 1 AS subcategories_count,
          COUNT(p.id) AS products_count
        FROM category_tree ct
        LEFT JOIN products p ON p.product_category_id = ct.id
      SQL

      row = ApplicationRecord.connection.select_one(
        ApplicationRecord.sanitize_sql_array([sql, id])
      )

      {
        subcategories_count: row["subcategories_count"].to_i,
        products_count: row["products_count"].to_i
      }
    end
  end

  # Preloaduje liczniki dla wielu kategorii naraz
  scope :with_aggregated_counts, -> {
    # Tworzymy pomocniczą tabelę z licznikami dla każdej kategorii
    subquery = <<~SQL
      SELECT
        pc_outer.id,
        (
          WITH RECURSIVE category_tree AS (
            SELECT id FROM product_categories WHERE id = pc_outer.id
            UNION ALL
            SELECT pc_inner.id
            FROM product_categories pc_inner
            JOIN category_tree ct ON pc_inner.product_category_id = ct.id
          )
          SELECT COUNT(*) - 1 FROM category_tree
        ) AS subcategories_count,
        (
          WITH RECURSIVE category_tree AS (
            SELECT id FROM product_categories WHERE id = pc_outer.id
            UNION ALL
            SELECT pc_inner.id
            FROM product_categories pc_inner
            JOIN category_tree ct ON pc_inner.product_category_id = ct.id
          )
          SELECT COUNT(*)
          FROM products p
          JOIN category_tree ct ON p.product_category_id = ct.id
        ) AS products_count
      FROM product_categories pc_outer
    SQL

    joins("LEFT JOIN (#{subquery}) counts ON counts.id = product_categories.id")
      .select("product_categories.*, counts.subcategories_count, counts.products_count")
  }

  # Liczba bezpośrednich dzieci (preloadowane przez includes)
  def direct_subcategories_count
    subcategories.size
  end

  # Liczba bezpośrednich produktów (preloadowane przez includes)
  def direct_products_count
    products.size
  end

  def total_subcategories_count
    aggregated_counts[:subcategories_count]
  end

  def total_products_count
    aggregated_counts[:products_count]
  end

  def self.quick_search
    :name_cont
  end

  private

  # generacja slug ("Smartfony i tablety" -> "smartfony-i-tablety")
  def generate_slug
    self.slug = name.parameterize
  end

  # generacja unikalnego kodu kategorii ("ELE", "SMA1", etc.)
  def generate_code
    return if code.present?

    base = name.to_s.parameterize(preserve_case: true, separator: '').upcase[0,3]
    base = SecureRandom.alphanumeric(3).upcase if base.blank?

    ProductCategory.transaction do
      ProductCategory.where(organization_id: organization_id).lock

      candidate = base
      counter = 0

      while ProductCategory.exists?(organization_id: organization_id, code: candidate)
        counter += 1
        candidate = "#{base}#{counter}"
      end

      update_column(:code, candidate)
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "description", "disabled", "id_by_org", "name", "position", "product_category_id", "slug", "updated_at", "visible"]
  end
end
