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
  include Tenantable
  include Destroyable
  include Loggable
  include OrganizationScoped

  # === RELACJE ===
  belongs_to :organization
  belongs_to :client
  belongs_to :user

  has_many :calculations, as: :calculable, dependent: :destroy
  has_one :order

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

  def self.for_user(user)
    all
  end


  # === STATUSY ===
  include AASM

  aasm column: :status do
    state :brand_new, initial: true
    state :in_preparation
    state :sent
    state :accepted
    state :converted_to_order
    state :not_accepted
    state :rejected

    event :prepare do
      transitions from: [:brand_new, :not_accepted], to: :in_preparation
    end

    event :go_back_to_new do
      transitions from: :in_preparation, to: :brand_new
    end

    event :send_to_client do
      transitions from: :in_preparation, to: :sent
    end

    event :accept do
      transitions from: :sent, to: :accepted
    end

    event :mark_as_not_accepted do
      transitions from: [:sent, :accepted, :converted_to_order], to: :not_accepted
    end

    event :convert_to_order do
      transitions from: :accepted, to: :converted_to_order
    end

    event :revert_from_order do
      transitions from: :converted_to_order, to: :accepted
    end

    event :reject do
      transitions from: [:brand_new, :in_preparation, :not_accepted], to: :rejected
    end
  end

  # zwraca event AASM dla danego statusu (mapowanie status -> event)
  def self.event_for_status(status)
    case status.to_sym
    when :brand_new then :go_back_to_new
    when :in_preparation then :prepare
    when :sent then :send_to_client
    when :accepted then :accept
    when :not_accepted then :mark_as_not_accepted
    when :converted_to_order then :convert_to_order
    when :rejected then :reject
    else nil
    end
  end

  # akcje dostępne dla aktualnego statusu oferty
  def status_actions
    case self.status.to_sym
    when :brand_new, :in_preparation
      [
        { 
          label: "Dodaj pozycje", 
          path: Rails.application.routes.url_helpers.offer_path(self, tab: "calculations"),
        }
      ]
    when :accepted
      [
        { 
          label: "Utwórz zamówienie", 
          path: Rails.application.routes.url_helpers.new_order_path(offer_id: self.id)
        }
      ]
    else
      []
    end
  end



  # === METODY ===
   
  # aktualne obliczenie oferty
  def current_calculation
    calculations.where(is_current: true).order(created_at: :desc).first
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

  # STATUSY
  # kolory statusów
  def self.status_color(status)
    case status.to_s
    when "brand_new"
      "#959696" # jasny szary
    when "in_preparation"
      "#3B82F6" # niebieski
    when "sent"
      "#6366F1" # indigo
    when "accepted"
      "#22C55E" # zielony 
    when "converted_to_order"
      "#15803D" # ciemny zielony
    when "not_accepted"
      "#F59E0B" # pomarańczowy
    when "rejected"
      "#374151" # ciemny szary
    else
      "#959696"
    end
  end

  def status_color
    Offer.status_color(self.status)
  end

  # czy kalkulacja może być edytowana
  def editable?
    brand_new? || in_preparation? || not_accepted?
  end

  def status_label
    I18n.t("activerecord.attributes.offer.statuses.#{self.status}")
  end

  def self.quick_search
    :number_or_external_number_cont
  end

  def set_offer_number
    return unless number.blank? || id_by_org.blank?

    update_column(:number, "F-#{organization_id}-#{Time.current.year}-#{id_by_org}")
  end

  def self.ransackable_attributes(auth_object = nil)
    ["client_id", "created_at", "external_number", "id", "id_by_org", "number", "organization_id", "status", "updated_at", "user_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["calculations", "client", "logs", "organization", "user"]
  end

  private

  # Tworzy wstępne obliczenie draft
  def create_initial_calculation
    calculations.build(
      user_id: self.user_id || Current.user&.id,
      is_current: true
    )
  end

end
