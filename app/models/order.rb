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

  # === WALIDACJE ===
  validates :client, presence: true
  validates :number, presence: true, uniqueness: { scope: :organization_id }
  validates :external_number, uniqueness: { scope: :organization_id }, allow_blank: true

  # === STATUSY ===
  include AASM

  aasm column: :status do
    state :pending, initial: true
    state :processing
    state :completed
    state :cancelled

    event :process do
      transitions from: :pending, to: :processing
    end

    event :complete do
      transitions from: :processing, to: :completed
    end

    event :cancel do
      transitions from: [:pending, :processing], to: :cancelled
    end
  end

  # === SCOPE ===
  scope :for_client, ->(client_id) { where(client_id: client_id) }
  scope :recent, -> { order(created_at: :desc) }

  # === CALLBACKI ===
  before_create :create_initial_calculation
  after_create :set_order_number



  # === METODY ===
  
  def self.for_user(user)
    all
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
    when "pending" then "gray"
    when "processing" then "blue"
    when "completed" then "green"
    when "cancelled" then "red"
    else "gray"
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
      calculations.build(
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
