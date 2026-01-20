# === Order ===
#
# Model reprezentuje zamówienie klienta.
# Zamówienie może mieć wiele obliczeń (różne scenariusze/wersje) które dziedziczą po OPCJONALNEJ ofercie
# Zamówienie należy do klienta, oraz OPCJONALNIE do oferty i OPCJONALNIE do użytkownika który je utworzył (z powodu przyszłego API)
#
# Atrybuty:
# - organization_id:bigint -> multi tenant
# - id_by_org:integer -> unikalny identyfikator w ramach organizacji
# - client_id:bigint -> klient
# - user_id:bigint -> użytkownik który utworzył
# - number:string -> numer zamówienia
# - external_number:string -> numer zewnętrzny od klienta


class Order < ApplicationRecord
  include Tenantable
  include Destroyable
  include Loggable
  include OrganizationScoped

  # === RELACJE ===
  belongs_to :client
  belongs_to :offer, optional: true
  belongs_to :user, optional: true

  has_many :calculations, as: :calculable, dependent: :destroy
  has_one :shipment, dependent: :destroy

  # === WALIDACJE ===
  validates :client, presence: true
  validates :number, uniqueness: { scope: :organization_id }
  validates :external_number, uniqueness: { scope: :organization_id }, allow_blank: true

  # === STATUSY ===
  include AASM

  aasm column: :status do
    state :brand_new, initial: true # nowe puste zamówienie
    state :in_preparation # w przygotowaniu (dodawanie/edytowanie pozycji, otwarte zamówienie)
    state :approved # zatwierdzone - rezerwacja wariantów, początek realizacji
    state :in_progress # w realizacji - wydawanie wariantów
    state :ready # gotowe - wydane/spakowane produkty (koniec kompletacji, opcjonalnie utworzona przesyłka)
    state :completed # zrealizowane - wydane
    state :closed # zamknięte - 100% zrealizowania zamówienia
    state :cancelled # anulowane
    state :on_hold # wstrzymane
    state :complaint # reklamacja

    event :process do
      transitions from: :brand_new, to: :in_preparation
    end

    event :approve do
      transitions from: :in_preparation, to: :approved
    end

    event :start_progress do
      transitions from: :approved, to: :in_progress
    end

    event :complete do
      transitions from: :in_progress, to: :completed
    end

    event :cancel do
      transitions from: [:brand_new, :in_preparation, :approved, :in_progress], to: :cancelled
    end
  end

  # zwraca event AASM dla danego statusu (mapowanie status -> event)
  def self.event_for_status(status)
    case status.to_sym
    when :brand_new then nil # status początkowy, brak eventu wstecz
    when :in_preparation then :process
    when :approved then :approve
    when :in_progress then :start_progress
    when :ready then nil # TODO: dodać event mark_ready
    when :completed then :complete
    when :closed then nil # TODO: dodać event close
    when :cancelled then :cancel
    when :on_hold then nil # TODO: dodać event hold
    when :complaint then nil # TODO: dodać event complain
    else nil
    end
  end

  # akcje dostępne dla aktualnego statusu zamówienia
  def status_actions
    case self.status.to_sym
    when :brand_new, :in_preparation
      [
        { 
          label: "Dodaj pozycje", 
          path: Rails.application.routes.url_helpers.order_path(self, tab: "calculations"),
        }
      ]
    when :approved
      [
        { 
          label: "Rozpocznij realizację", 
          path: Rails.application.routes.url_helpers.order_path(self),
        }
      ]
    else
      []
    end
  end

  # === SCOPE ===
  scope :for_client, ->(client_id) { where(client_id: client_id) }
  scope :recent, -> { order(created_at: :desc) }

  def self.for_user(user)
    all
  end

  # === CALLBACKI ===
  after_create :create_initial_calculation
  after_create :set_order_number



  # === METODY ===
  
  # aktualne obliczenie oferty
  def current_calculation
    calculations.where(is_current: true).order(created_at: :desc).first
  end

  # czy kalkulacja (wersja) jest zatwierdzona
  def has_confirmed_calculation?
    current_calculation&.confirmed?
  end

  # operacje magazynowe dla aktualnej kalkulacji (wersji)
  def stock_operations
    current_calculation&.stock_operations || StockOperation.none
  end

  def self.icon
    "shopping-cart"
  end

  def status_label
    I18n.t("activerecord.attributes.order.statuses.#{self.status}")
  end

  def status_color
    Order.status_color(self.status)
  end

  def self.status_color(status)
    case status.to_s
    when "brand_new"
      "#959696" # jasny szary
    when "in_preparation"
      "#3B82F6" # niebieski
    when "approved"
      "#6366F1" # indigo
    when "in_progress"
      "#F59E0B" # pomarańczowy
    when "ready"
      "#22C55E" # zielony
    when "completed"
      "#15803D" # ciemny zielony
    when "closed"
      "#374151" # ciemny szary
    when "cancelled"
      "#EF4444" # czerwony
    when "on_hold"
      "#D97706" # ciemny pomarańczowy
    when "complaint"
      "#DC2626" # ciemny czerwony
    else
      "#959696"
    end
  end

  def self.quick_search
    :number_or_external_number_cont
  end

  private

  def set_order_number
    return unless number.blank? || id_by_org.blank?

    update_column(:number, "O-#{organization_id}-#{Time.current.year}-#{id_by_org}")
  end

  def create_initial_calculation
    if offer&.calculations&.any?
      Calculations::CopyToOrder.call(
        order: self,
        offer: offer,
        user: user
      )
    else
      calculations.create!(
        user_id: self.user_id || Current.user&.id,
        is_current: true
      )
    end
  end

  def self.ransackable_attributes(auth_object = nil)
    ["client_id", "created_at", "disabled", "external_number", "id", "id_by_org", "number", "offer_id", "organization_id", "status", "updated_at", "user_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["client", "offer", "user"]
  end

end
