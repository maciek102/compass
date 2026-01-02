# === Variant ===
#
# Model reprezentuje wariant produktu.
# To odmiana produktu, np. „Koszulka – rozm. M – kolor czarny”.
#
# Pełni rolę:
# - odmiany produktu (atrybuty: rozmiar, kolor, materiał…)
# - nośnika ceny (ma swoją cenę, niezależną od produktu)
# - nośnika SKU / EAN
# - powiązania z itemami (fizycznymi egzemplarzami)
#
# Atrybuty:
# - organization_id:bigint -> multi tenant
# - id_by_org:integer -> unikalny identyfikator produktu w ramach organizacji
# - name:string -> nazwa
# - sku:string -> unikalny SKU 
# - ean:string -> kod kreskowy
# - price:decimal -> cena
# - stock:integer -> uproszczona ilość magazynowa
# - weight:decimal -> waga
# - custom_attributes:jsonb -> elastyczne cechy (np. {color:"red", size:"XL"})
# - disabled:boolean -> soft-delete
# - note:text -> notatki wewnętrzne
# - image:active_storage -> zdjęcia

class Variant < ApplicationRecord
  include Destroyable
  include Loggable
  include OrganizationScoped

  # === RELACJE ===
  belongs_to :organization
  belongs_to :product
  # itemy fizyczne
  has_many :items, dependent: :destroy
  # ruchy magazynowe
  has_many :stock_operations, dependent: :destroy
  # historia zmian
  has_many :logs, as: :loggable, dependent: :destroy

  has_one_attached :barcode_image # kod kreskowy
  has_one_attached :qr_code_image # kod QR

  has_many_attached :images # zdjęcie

  # === WALIDACJE ===
  validates :name, presence: true
  validates :sku, uniqueness: { scope: :organization_id, allow_blank: true }
  validates :ean, uniqueness: { scope: :organization_id, allow_blank: true }
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # === STATUSY ===
  # enum :status, {
  #   draft: 0, # w trakcie tworzenia
  #   available: 1, # dostępny w sprzedaży
  # }

  # === SCOPE ===
  scope :active, -> { where(disabled: false) } # niezarchiwizowane
  scope :available_for_sale, -> { where(disabled: false, status: statuses[:available]) } # widoczne, aktywne dla klienta
  scope :of_product, ->(product_id) { where(product_id: product_id) }

  # === CALLBACKI ===
  before_validation :assign_default_name, if: -> { name.blank? }
  before_validation :set_default_stock, if: -> { stock.nil? }
  before_save :generate_sku, if: -> { sku.blank? }



  # === METODY ===
   
  def self.for_user(user)
    default_scope = for_organization(user.organization_id)
    default_scope
  end
   
  def self.icon
    "cube"
  end

  # faktyczna ilość dostępna
  def current_stock
    stock || 0
  end

  # przeliczenie stanu magazynowego na podstawie ruchów magazynowych
  def recalculate_stock!
    total = stock_operations.joins(:stock_movements).sum("stock_movements.quantity * stock_movements.direction")
    update_column(:stock, total)
  end

  # czy można kupić?
  def can_be_sold?
    !disabled && total_stock > 0
  end

  def self.quick_search
    :name_or_sku_or_product_name_cont
  end

  private

  def generate_sku
    return if sku.present?

    raise "Product code missing" if product&.code.blank?
    raise "Category code missing" if product&.category&.code.blank?

    cat_code  = product.category.code.to_s.strip.upcase
    prod_code = product.code.to_s.strip.upcase

    next_number = Variant.where(organization_id: organization_id, product_id: product_id).count + 1

    candidate = format("%s-%s-%03d", cat_code, prod_code, next_number)

    counter = 0
    while Variant.where(organization_id: organization_id).where(sku: candidate).where.not(id: id).exists?
      counter += 1
      candidate = format("%s-%s-%03d", cat_code, prod_code, next_number + counter)
    end

    self.sku = candidate
  end

  def assign_default_name
    self.name ||= "V #{sku || product.variants.count + 1}"
  end

  def set_default_stock
    self.stock ||= 0
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "custom_attributes", "disabled", "ean", "id_by_org", "location", "name", "note", "price", "product_id", "sku", "stock", "updated_at", "weight"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["items", "product", "stock_movements"]
  end
end
