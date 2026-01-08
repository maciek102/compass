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
# - discount_percent:decimal -> rabat w %
# - discount_amount:decimal -> rabat w kwocie
# - margin_percent:decimal -> marża w %
# - margin_amount:decimal -> marża w kwocie
# - vat_percent:decimal -> stawka VAT %
# - vat_amount:decimal -> kwota VAT
# - subtotal:decimal -> ilość * cena jednostkowa
# - discount_total:decimal -> rabat łącznie
# - margin_total:decimal -> marża łącznie
# - total_net:decimal -> netto (po rabatach i marżach)
# - total_gross:decimal -> brutto (z VAT)

class CalculationRow < ApplicationRecord
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
  before_save :calculate_totals

  # === SCOPES ===
  scope :by_calculation, ->(calculation_id) { where(calculation_id: calculation_id) }
  scope :with_variant, -> { where.not(variant_id: nil) }
  scope :without_variant, -> { where(variant_id: nil) }
  scope :ordered, -> { order(:position) }

  # === INSTANCE METHODS ===

  # Zwraca czy to wiersz produktu czy niestandardowy
  def standard?
    variant_id.present?
  end

  def custom?
    !standard?
  end

  # Oblicza i zapisuje wszystkie sumy
  def calculate_totals
    # Subtotal = ilość * cena jednostkowa
    self.subtotal = (quantity * unit_price).round(2)

    # Rabat
    if discount_percent.present? && discount_percent > 0
      self.discount_total = (subtotal * (discount_percent / 100)).round(2)
    elsif discount_amount.present?
      self.discount_total = discount_amount.round(2)
    else
      self.discount_total = 0
    end

    # Marża
    if margin_percent.present? && margin_percent > 0
      self.margin_total = (subtotal * (margin_percent / 100)).round(2)
    elsif margin_amount.present?
      self.margin_total = margin_amount.round(2)
    else
      self.margin_total = 0
    end

    # Netto (po rabatach i marżach)
    self.total_net = (subtotal - discount_total + margin_total).round(2)

    # VAT
    if vat_percent.present? && vat_percent > 0
      self.vat_amount = (total_net * (vat_percent / 100)).round(2)
    else
      self.vat_amount = 0
    end

    # Brutto (netto + VAT)
    self.total_gross = (total_net + vat_amount).round(2)
  end

  # Metoda do pobrania nazwy z wariantu jeśli nie ustawiono własnej nazwy
  def display_name
    name.presence || variant&.name || "Wiersz niestandardowy"
  end

  # Metoda do pobrania opisu z wariantu jeśli nie ustawiono własnego
  def display_description
    description.presence || variant&.note
  end
end
