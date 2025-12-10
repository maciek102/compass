# === ProductCategory ===
#
# Model reprezentuje kategorię produktów w systemie. Pozwala na:
# - grupowanie produktów w kategorie i podkategorie
# - hierarchiczne drzewo kategorii
# - zarządzanie widocznością i kolejnością wyświetlania
#
# Atrybuty:
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
  include Destroyable

  # relacja hierarchiczna
  belongs_to :parent, class_name: "ProductCategory", foreign_key: "product_category_id", optional: true
  has_many :subcategories, class_name: "ProductCategory", foreign_key: "product_category_id", dependent: :destroy
  accepts_nested_attributes_for :subcategories, allow_destroy: true

  # === RELACJE ===
  # produkty należące do kategorii
  has_many :products, dependent: :destroy

  has_one_attached :main_image # główne zdjęcie kategorii
  has_many_attached :private_images # zdjęcia robocze / prywatne

  # === WALIDACJE ===
  validates :name, presence: true
  validates :slug, uniqueness: true, allow_blank: true
  validates :code, uniqueness: true

  # === SCOPE ===
  scope :active, -> { where(disabled: false) } # niezarchiwizowane
  scope :visible, -> { where(visible: true, disabled: false) }

  # === CALLBACKI ===
  before_validation :generate_slug, if: -> { name.present? }
  after_save :generate_code, if: -> { code.blank? }


  # === METODY ===
  
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

    clean_name = name.to_s.strip
    clean_name = clean_name.parameterize(preserve_case: true, separator: '')
    
    base = clean_name.upcase[0,3]
    base = SecureRandom.alphanumeric(3).upcase if base.blank? || base.length < 3
    base = "#{base[0,3]}#{id}"

    self.update_column(:code, base)
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "description", "disabled", "id", "name", "position", "product_category_id", "slug", "updated_at", "visible"]
  end
end
