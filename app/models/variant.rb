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

  # === RELACJE ===
  belongs_to :product

  # itemy fizyczne
  has_many :items, dependent: :destroy

  has_many_attached :images # zdjęcie

  # === WALIDACJE ===
  validates :name, presence: true
  validates :sku, uniqueness: true, allow_blank: true
  validates :ean, uniqueness: true, allow_blank: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  # === STATUSY ===
  enum status: {
    draft: 0, # w trakcie tworzenia
    available: 1, # dostępny w sprzedaży
  }

  # === SCOPE ===
  scope :active, -> { where(disabled: false) } # niezarchiwizowane
  scope :available_for_sale, -> { where(disabled: false, status: statuses[:available]) } # widoczne, aktywne dla klienta
  scope :of_product, ->(product_id) { where(product_id: product_id) }

  # === CALLBACKI ===
  before_validation :assign_default_name, if: -> { name.blank? }



  # === METODY ===

  # faktyczna ilość dostępna
  def total_stock
    items.count || stock.to_i
  end

  # czy można kupić?
  def can_be_sold?
    !disabled && total_stock > 0
  end

  private

  def assign_default_name
    self.name ||= "V #{sku || SecureRandom.hex(3)}"
  end
end
