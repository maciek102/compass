# === CalculationRow ===
#
# Model reprezentuje pojedynczy wiersz w obliczeniu (pozycję w ofercie, zamówieniu, itp.)
# Wiersz może być powiązany z wariantem produktu lub być wierszem niestandardowym
# (np. extra koszty realizacji, usługi dodatkowe, itp.)
#
# Atrybuty:
# - calculation_id:bigint -> obliczenie
# - variant_id:bigint -> wariant produktu (opcjonalny)
# - position:integer -> kolejność wiersza
# - name:string -> nazwa wiersza
# - description:text -> opis wiersza
# - quantity:decimal -> ilość
# - unit:string -> jednostka miary (szt., kg, l, m, itp.)
# - unit_price:decimal -> cena jednostkowa netto
# - vat_percent:decimal -> stawka VAT %
# - subtotal:decimal -> ilość * cena jednostkowa
# - discount_total:decimal -> rabat łącznie
# - margin_total:decimal -> marża łącznie
# - total_net:decimal -> netto (po rabatach i marżach)
# - total_gross:decimal -> brutto (z VAT)

class CalculationRow < ApplicationRecord
  include Tenantable
  include Loggable

  # === RELACJE ===
  belongs_to :calculation
  belongs_to :variant, optional: true
  has_many :row_adjustments, dependent: :destroy

  # === WALIDACJE ===
  validates :calculation_id, presence: true
  validates :name, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # === CALLBACK ===
  #before_save :calculate_totals

  # === SCOPES ===
  scope :by_calculation, ->(calculation_id) { where(calculation_id: calculation_id) }
  scope :with_variant, -> { where.not(variant_id: nil) }
  scope :without_variant, -> { where(variant_id: nil) }
  scope :ordered, -> { order(:position) }

  # === JEDNOSTKI ===
  enum :unit, {
    piece: 0, # sztuka
    kilogram: 1, # kilogram
    liter: 2, # litr
    meter: 3, # metr
    hour: 4, # godzina
    service: 5 # usługa
  }


  # === METODY ===

  # standardowy wiersz / pozycja - ma przypisany produkt (wariant)
  def standard?
    variant_id.present?
  end

  # niestandardowy wiersz / pozycja - brak przypisanego produktu (wariantu), np. usługa dodatkowa
  def custom?
    !standard?
  end

  def total_price
    total_gross
  end

  def display_name
    name.presence || variant&.name || "Wiersz niestandardowy"
  end

  def self.quick_search
    :name_or_position_cont
  end

  def self.ransackable_attributes(auth_object = nil)
    ["calculation_id", "created_at", "description", "id", "name", "organization_id", "position", "quantity", "subtotal", "total_gross", "total_net", "unit", "unit_price", "updated_at", "variant_id", "vat_percent"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["calculation", "variant"]
  end
end
