# === Calculation ===
#
# Model reprezentuje obliczenie (zbiór wierszy z pozycjami, cenami, rabatami, marżami, VAT).
# Każda oferta/zamówienie/faktura może mieć wiele obliczeń (różne scenariusze, wersje).
# Umożliwia wersjonowanie - każda edycja tworzy nowe obliczenie.
#
# Atrybuty:
# - organization_id:bigint -> multi tenant
# - id_by_org:integer -> unikalny identyfikator w ramach organizacji
# - calculable_id:bigint -> ID głównego dokumentu (Offer, Order, itp.)
# - calculable_type:string -> typ głównego dokumentu ("Offer", "Order", itp.)
# - number:integer -> numer obliczenia
# - calculation_number:string -> numer dla wyświetlania
# - status:string -> draft, sent, accepted, rejected, archived
# - valid_until:datetime -> ważne do
# - sent_at:datetime -> wysłane w
# - accepted_at:datetime -> zaakceptowane w
# - rejected_at:datetime -> odrzucone w
# - notes:text -> notatki
# - user_id:bigint -> autor

class Calculation < ApplicationRecord
  include Tenantable
  include Destroyable
  include OrganizationScoped

  # === POLYMORPHIC ASSOCIATION ===
  belongs_to :calculable, polymorphic: true

  # === RELACJE ===
  belongs_to :user, optional: true

  has_many :calculation_rows, dependent: :destroy
  has_many :row_adjustments, through: :calculation_rows
  has_many :stock_operations, dependent: :nullify
  accepts_nested_attributes_for :calculation_rows, allow_destroy: true


  # === WALIDACJE ===
  validates :calculable_id, presence: true
  validates :calculable_type, presence: true, inclusion: { in: %w(Offer Order Invoice) }
  validates :version_number, presence: true, numericality: { only_integer: true, greater_than: 0 }

  # === CALLBACK ===
  before_validation :set_version_number, on: :create

  # === SCOPES ===
  scope :by_type, ->(type) { where(calculable_type: type) }
  scope :by_document, ->(doc_id, doc_type) { where(calculable_id: doc_id, calculable_type: doc_type) }
  scope :recent, -> { order(created_at: :desc) }

  # === INSTANCE METHODS ===

  # Wszystkie wiersze
  def rows
    calculation_rows.order(:position).includes(:row_adjustments) || []
  end

  # Liczba wierszy
  def rows_count
    calculation_rows.count
  end

  def current?
    is_current
  end

  def confirmed?
    confirmed_at.present?
  end

  def editable?
    !confirmed?
  end

  def title
    "Wersja ##{version_number}"
  end

  private

  # Ustaw numer obliczenia
  def set_version_number
    self.version_number = calculable.calculations.count + 1 if version_number.blank?
  end
end
