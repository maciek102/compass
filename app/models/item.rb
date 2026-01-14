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
  include Tenantable
  include Destroyable
  include OrganizationScoped

  # === RELACJE ===
  belongs_to :organization # wieloorganizacyjność
  belongs_to :variant # należy do wariantu
  belongs_to :reserved_stock_operation, class_name: "StockOperation", optional: true

  # posiada wiele operacji magazynowych
  has_many :stock_movement_items
  has_many :stock_movements, through: :stock_movement_items

  has_many_attached :images # zdjęcia

  # === STATUSY ===
  enum :status, {
    in_stock: 0, # w magazynie, dostępny
    reserved: 1, # zarezerwowany pod zamówienie
    issued: 2, # wydany
    returned: 3, # zwrócony od klienta
    damaged: 4 # uszkodzony
  }

  # === WALIDACJE ===
  validates :serial_number, uniqueness: { scope: :organization_id, allow_blank: true }
  validates :status, presence: true

  # === SCOPE ===
  scope :available, -> { active.in_stock } # egzemplarze które można wydać 
  scope :available_for_calculation, ->(calculation) { # egzemplarze dostępne dla danej kalkulacji (uwzględnia rezerwacje)
    if calculation.present?
      where("status = ? OR (status = ? AND reserved_stock_operation_id IN (?))", Item.statuses[:in_stock], Item.statuses[:reserved], calculation.stock_operations.select(:id))
    else
      where(status: Item.statuses[:in_stock])
    end
  }
  scope :of_variant, ->(variant_id) { where(variant_id: variant_id) }

  # === CALLBACKI ===
  before_validation :set_default_status, if: -> { status.blank? }
  before_validation :set_default_received_at, if: -> { received_at.blank? }
  before_save :generate_default_serial_number, if: -> { serial_number.blank? }
  # o każdej zmianie przeliczamy stock wariantu
  after_commit :recalculate_variant_stock!, on: [:create, :update, :destroy]



  # === METODY ===
  
  def self.for_user(user)
    all
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

  # przelicza stan magazynowy powiązanego wariantu
  def recalculate_variant_stock!
    variant.recalculate_stock!
  end

  # rezerwacja egzemplarza pod daną operację magazynową
  def reserve_for!(operation)
    update!(status: :reserved, reserved_stock_operation: operation)
  end

  # zwolnienie rezerwacji
  def unreserve!
    update!(status: :in_stock, reserved_stock_operation: nil)
  end

  # generacja domyślnego numeru seryjnego
  def generate_default_serial_number
    return if serial_number.present?
    raise "Variant missing" if variant.nil?
    raise "Variant SKU missing" if variant.sku.blank?

    base_sku = variant.sku

    next_number = Item.where(organization_id: organization_id, variant_id: variant_id).count + 1

    candidate = format("%s-%06d", base_sku, next_number)

    counter = 0
    while Item.where(organization_id: organization_id).where(serial_number: candidate).exists?
      counter += 1
      candidate = format("%s-%06d", base_sku, next_number + counter)
    end

    self.serial_number = candidate
  end

  # generacja proponowanego numeru seryjnego, używana na nieutworzonych obiektach np przy receive
  def generate_proposed_serial_number
    return if variant.nil? || variant.sku.blank?

    base_sku = variant.sku

    if respond_to?(:serial_number_base)
      # użycie base i offset (ustawiane w kontrolerze, aby uniknąć n+1)
      offset = respond_to?(:serial_number_offset) ? serial_number_offset : 0
      next_number = serial_number_base + offset
    else
      # fallback – domyślne liczenie od nowa
      next_number = Item.where(organization_id: organization_id, variant_id: variant_id).count + 1
      offset = respond_to?(:serial_number_offset) ? serial_number_offset : 0
      next_number += offset
    end

    format("%s-%06d", base_sku, next_number)
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
