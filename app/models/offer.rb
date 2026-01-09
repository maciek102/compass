# === Offer ===
#
# Model reprezentuje ofertę dla klienta.
# Oferta może mieć wiele obliczeń (różne scenariusze/wersje).
# Każde obliczenie zawiera wiersze (CalculationRow).
#
# Atrybuty:
# - organization_id:bigint -> multi tenant
# - id_by_org:integer -> unikalny identyfikator w ramach organizacji
# - client_id:bigint -> klient
# - user_id:bigint -> użytkownik który utworzył
# - number:string -> numer oferty
# - external_number:string -> numer zewnętrzny od klienta

class Offer < ApplicationRecord
  acts_as_tenant :organization

  include Destroyable
  include Loggable
  include OrganizationScoped

  # === RELACJE ===
  belongs_to :organization
  belongs_to :client
  belongs_to :user

  has_many :calculations, as: :calculable, dependent: :destroy
  has_many :logs, as: :loggable, dependent: :destroy

  # === WALIDACJE ===
  validates :organization_id, presence: true
  validates :client_id, presence: true
  validates :user_id, presence: true

  # === CALLBACK ===
  before_create :create_initial_calculation
  after_create :set_offer_number

  # === SCOPES ===
  scope :for_client, ->(client_id) { where(client_id: client_id) }
  scope :by_number, ->(number) { where(number: number) }
  scope :recent, -> { order(created_at: :desc) }

  # === INSTANCE METHODS ===
   
  def self.for_user(user)
    all
  end

  # Zwraca aktualne obliczenie oferty (ostatnie stworzone)
  def current_calculation
    calculations.where(is_current: true).order(created_at: :desc).first
  end

  # Tworzy nowe obliczenie (draft)
  def create_calculation!(user: nil)
    calculations.create!(
      status: "draft",
      user_id: user&.id || self.user_id
    )
  end

  # Klonuje ostatnie obliczenie i tworzy nowe na jego podstawie
  def create_calculation_from_current!(user: nil)
    current = current_calculation
    return create_calculation!(user: user) unless current

    new_calculation = calculations.build(
      status: "draft",
      user_id: user&.id || self.user_id,
      notes: current.notes,
      valid_until: current.valid_until
    )

    new_calculation.save!

    # Skopiuj wiersze z ostatniego obliczenia
    current.calculation_rows.each do |row|
      new_calculation.calculation_rows.create!(
        variant_id: row.variant_id,
        position: row.position,
        name: row.name,
        description: row.description,
        quantity: row.quantity,
        unit: row.unit,
        unit_price: row.unit_price,
      )
    end

    new_calculation
  end

  # Zwraca wszystkie wiersze z aktualnego obliczenia
  def current_rows
    current_calculation&.calculation_rows&.ordered || []
  end

  # Zwraca sumę netto z aktualnego obliczenia
  def current_total_net
    current_calculation&.total_net || 0
  end

  # Zwraca sumę brutto z aktualnego obliczenia
  def current_total_gross
    current_calculation&.total_gross || 0
  end

  def self.icon
    "file"
  end

  def self.quick_search
    :number_or_external_number_cont
  end

  def set_offer_number
    return unless number.blank? || id_by_org.blank?

    update_column(:number, "F-#{organization_id}-#{Time.current.year}-#{id_by_org}")
  end

  private


  # Tworzy wstępne obliczenie draft
  def create_initial_calculation
    calculations.build(
      user_id: self.user_id || Current.user&.id,
      is_current: true
    )
  end

  def self.ransackable_attributes(auth_object = nil)
    ["client_id", "created_at", "external_number", "id", "id_by_org", "number", "organization_id", "updated_at", "user_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["calculations", "client", "logs", "organization", "user"]
  end

end
