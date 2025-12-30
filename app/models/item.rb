# === Item ===
#
# Model reprezentuje fizyczną sztukę towaru - egzemplarz.
# W odróżnieniu od produktu i wariantu – Item istnieje fizycznie.
# To odpowiednik np. konkretnej koszulki, rozmiar M, kod #123 (pojedynczego egzemplarza w magazynie)
#
# Pozwala na:
# - śledzenie każdego egzemplarza
# - oznaczyć egzemplarze uszkodzone, zwrócone, zarezerwowane do sprzedaży
#
# Atrybuty:
# - variant_id:bigint -> do którego wariantu należy
# - serial_number:string -> numer seryjny (opcjonalny)
# - batch:string -> numer partii (opcjonalny)
# - expires_at:datetime -> data ważności (opcjonalnie)
# - received_at:datetime -> WAŻNE!!! - data przyjęcia na magazyn, główne kryterium strategii wyboru produktów ItemPicker
# - status:integer -> status itemu
# - custom_attributes:jsonb -> dodatkowe informacje
# - disabled:boolean -> soft-delete
# - note:text -> notatki
# - images:active_storage -> zdjęcia egzemplarza

class Item < ApplicationRecord
  include Destroyable
  include OrganizationScoped

  # === RELACJE ===
  belongs_to :organization # wieloorganizacyjność
  belongs_to :variant # należy do wariantu

  # posiada wiele operacji magazynowych
  has_many :stock_movement_items
  has_many :stock_movements, through: :stock_movement_items

  has_many_attached :images # zdjęcia

  # === STATUSY ===
  enum :status, {
    in_stock: 0, # w magazynie, dostępny
    reserved: 1, # zarezerwowany pod zamówienie
    sold: 2, # sprzedany
    returned: 3, # zwrócony od klienta
    damaged: 4 # uszkodzony
  }

  # === WALIDACJE ===
  validates :serial_number, uniqueness: true, allow_blank: true
  validates :status, presence: true

  # === SCOPE ===
  scope :active, -> { where(disabled: false) }
  scope :available, -> { active.in_stock } # egzemplarze które można sprzedać
  scope :of_variant, ->(variant_id) { where(variant_id: variant_id) }

  # === CALLBACKI ===
  before_validation :set_default_status, if: -> { status.blank? }
  before_validation :set_default_received_at, if: -> { received_at.blank? }
  after_save :generate_default_serial_number, if: -> { serial_number.blank? }



  # === METODY ===
  
  def self.for_user(user)
    default_scope = for_organization(user.organization_id)
    default_scope
  end

  # czy item jest dostępny do sprzedaży?
  def available_for_sale?
    in_stock? && !disabled
  end

  # czy item jest w magazynie fizycznie?
  def physically_present?
    in_stock? || reserved? || returned?
  end

  def self.icon
    "square"
  end

  # generacja domyślnego numeru seryjnego
  def generate_default_serial_number
    return if id.nil? || variant.nil?
    serial_number = "#{variant.sku}-#{100 + (id_by_org || id)}"
    self.update_column(:serial_number, serial_number)
  end

  private

  def set_default_status
    self.status ||= :in_stock
  end

  # ustawienie daty przyjęcia na magazyn
  def set_default_received_at
    self.received_at ||= Time.current
  end
end
