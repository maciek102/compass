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
  after_save :generate_sku, if: -> { sku.blank? }
  after_create :log_creation
  after_update :log_update
  before_destroy :log_destruction


  # === METODY ===
   
  def self.icon
    "cube"
  end

  # faktyczna ilość dostępna
  def total_stock
    items.count || stock.to_i
  end

  # czy można kupić?
  def can_be_sold?
    !disabled && total_stock > 0
  end

  private

  # === LOGOWANIE ===

  def log_creation
    Log.created!(
      loggable: self,
      user: current_user_from_context,
      message: "Wariant #{name} został utworzony"
    )
  end

  def log_update
    if saved_changes.present?
      changes_hash = saved_changes.except(:updated_at)
      Log.updated!(
        loggable: self,
        user: current_user_from_context,
        message: "Wariant #{name} został zmieniony",
        details: changes_hash
      )
    end
  end

  def log_destruction
    Log.destroyed!(
      loggable: self,
      user: current_user_from_context,
      message: "Wariant #{name} został usunięty"
    )
  end

  def current_user_from_context
    RequestStore.store[:current_user]
  end

  def generate_sku
    return if sku.present?
    
    prod_sku = product&.sku || SecureRandom.alphanumeric(3).upcase
    base = "#{prod_sku}/#{100 + id}"
    
    self.update_column(:sku, base)
  end

  def assign_default_name
    self.name ||= "V #{sku || SecureRandom.hex(3)}"
  end
end
