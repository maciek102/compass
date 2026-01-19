# === Product ===
#
# Model reprezentuje produkt jako główny byt katalogowy.
# "Wzorzec" produktu, z którego mogą wynikać warianty (np. Koszulka - rozm. S,M,L) oraz fizyczne itemy (np. konkretna Koszulka - rozm. S #123).
# Pełni rolę:
# - nadrzędnego opisu produktu (nazwa, opis, kategoria)
# - kontenera dla wariantów (np. rozmiar, kolor)
# - źródła danych (zdjęcia, notatki, tagi)
# - miejsca integracji ze slugami, SEO oraz filtrowaniem
#
# Atrybuty:
# - organization_id:bigint -> multi tenant
# - id_by_org:integer -> unikalny identyfikator produktu w ramach organizacji
# - name:string -> nazwa produktu
# - description:text -> opis produktu
# - main_description:rich_text -> główny duży opis
# - notes:text -> notatki wewnętrzne
# - sku:string -> kod globalny produktu (opcjonalny, warianty mogą mieć własne)
# - code:string -> unikalny kod produktu
# - slug:string -> przyjazny adres URL
# - product_category_id:bigint -> kategoria
# - status:integer -> stan publikacji / widoczności
# - disabled:boolean -> soft-delete
# - main_image:active_storage -> główne zdjęcie produktu
# - gallery:active_storage -> dodatkowe zdjęcia
# - private_images:active_storage -> zdjęcia robocze

class Product < ApplicationRecord
  include Tenantable
  include Destroyable
  include Loggable
  include OrganizationScoped

  # === RELACJE ===
  belongs_to :organization
  # kategoria produktu
  belongs_to :category, class_name: "ProductCategory", foreign_key: "product_category_id"

  # warianty produktu
  has_many :variants, dependent: :destroy
  accepts_nested_attributes_for :variants

  has_one_attached :main_image # główne zdjęcie
  has_many_attached :gallery # dodatkowe zdjęcia
  has_many_attached :private_images # zdjęcia robocze

  has_rich_text :main_description # główny, duży opis rich text

  # === KOLEKCJE ===
  # statusy
  enum :status, {
    draft: 0, # w trakcie tworzenia
    available: 1, # dostępny w sprzedaży
  }

  # filtry
  FILTERS = [
    :name_cont,
    :code_cont,
    :sku_cont,
    :status_eq,
    :product_category_id_eq
  ].freeze

  # === WALIDACJE ===
  validates :name, presence: true
  validates :slug, uniqueness: { scope: :organization_id, allow_blank: true }
  validates :code, uniqueness: { scope: :organization_id, allow_blank: true }
  validates :sku, uniqueness: { scope: :organization_id, allow_blank: true }

  # === SCOPE ===
  scope :available_for_sale, -> { active.where(status: statuses[:available]) } # widoczne, aktywne dla klienta
  scope :with_category, ->(category_id) { where(product_category_id: category_id) }

  # === CALLBACKI ===
  before_validation :generate_slug, if: -> { name.present? }
  before_validation :set_default_status, if: -> { status.nil? }
  before_save :generate_code, if: -> { code.blank? }
  before_save :generate_sku, if: -> { sku.blank? }
  after_create :create_default_variant # tworzenie domyślnego wariantu w przypadku braku



  # === METODY ===
   
  def self.for_user(user)
    all
  end
  
  def self.icon
    "dropbox"
  end

  # Zwraca liczbę wszystkich fizycznych itemów we wszystkich wariantach
  def total_stock
    variants.sum { |v| v.stock.to_i }
  end

  # produkt nieużywający wariantów (posiada jeden domyślny)
  def single_varianted?
    variants.count == 1
  end

  # ransack
  def self.quick_search
    :name_or_sku_cont
  end

  private

  # generuje slug ("Smartfony i tablety" -> "smartfony-i-tablety")
  def generate_slug
    self.slug = name.parameterize
  end

  # generacja unikalnego kodu produktu ("IPH1", "XIA2", etc.)
  def generate_code
    return if code.present?

    base = name.to_s.parameterize(preserve_case: true, separator: '').upcase[0,3]
    base = SecureRandom.alphanumeric(3).upcase if base.blank?

    candidate = base
    counter = 0

    while Product.exists?(organization_id: organization_id, code: candidate)
      counter += 1
      candidate = "#{base}#{counter}"
    end

    self.code = candidate
  end

  def generate_sku
    return if sku.present?
    raise "Category code missing" if category&.code.blank?
    raise "Product code missing" if code.blank?

    cat_code  = category.code.to_s.strip.upcase
    cat_code  = cat_code.parameterize(preserve_case: true, separator: '')
    cat_code  = "XXX" if cat_code.blank?
    prod_code = code

    candidate = "#{cat_code}-#{prod_code}"
    counter = 0

    while Product.where(organization_id: organization_id).where(sku: candidate).exists?
      counter += 1
      candidate = "#{cat_code}-#{prod_code}#{counter}"
    end

    self.sku = candidate
  end
  
  def set_default_status
    self.status ||= :draft
  end

  # tworzenie domyślnego wariantu po utworzeniu produktu (jeśli nie istnieje)
  def create_default_variant
    return if variants.exists?

    variants.create!
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "description", "disabled", "id_by_org", "name", "notes", "product_category_id", "sku", "slug", "status", "updated_at", "code"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["category", "gallery_attachments", "gallery_blobs", "main_image_attachment", "main_image_blob", "private_images_attachments", "private_images_blobs", "rich_text_main_description", "variants"]
  end
end
