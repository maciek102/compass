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

  # === RELACJE ===
  belongs_to :product
  # itemy fizyczne
  has_many :items, dependent: :destroy
  # ruchy magazynowe
  has_many :stock_movements, dependent: :destroy

  has_many_attached :images # zdjęcie

  # === WALIDACJE ===
  validates :name, presence: true
  validates :sku, uniqueness: true, allow_blank: true
  validates :ean, uniqueness: true, allow_blank: true
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
  after_save :generate_sku, if: -> { sku.blank? }



  # === METODY ===
   
  def self.icon
    "cube"
  end

  # faktyczna ilość dostępna
  def current_stock
    stock || 0
  end

  # przeliczenie stanu magazynowego na podstawie ruchów magazynowych
  def recalculate_stock!
    total = stock_movements.sum("quantity * direction")
    update_column(:stock, total)
  end

  # czy można kupić?
  def can_be_sold?
    !disabled && total_stock > 0
  end

  private

  def generate_sku
    return if sku.present?
    
    prod_sku = product&.sku || SecureRandom.alphanumeric(3).upcase
    base = "#{prod_sku}/#{100 + id}"
    
    self.update_column(:sku, base)
  end

  def assign_default_name
    self.name ||= "V #{sku || product.variants.count + 1}"
  end

  def set_default_stock
    self.stock ||= 0
  end
end
