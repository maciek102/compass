class Shipment < ApplicationRecord
  include Tenantable
  include Loggable
  include Destroyable
  include OrganizationScoped

  # === RELACJE ===
  belongs_to :order
  has_one_attached :label

  # === ENUMY ===
  enum :provider, {
    inpost: 'inpost'
  }, prefix: true

  enum :delivery_type, {
    locker: 0,
    courier: 1
  }, prefix: true

  # === WALIDACJE ===
  validates :order, presence: true
  validates :provider, presence: true
  validates :recipient_name, presence: true
  validates :recipient_phone, presence: true
  validates :recipient_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :locker_code, presence: true, if: :delivery_type_locker?
  validates :address_street, :address_city, :address_postcode, :address_country, presence: true, if: :delivery_type_courier?

  # === SCOPES ===
  scope :active, -> { where(disabled: false) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_provider, ->(provider) { where(provider: provider) }

  # === CALLBACKI ===
  before_create :set_default_status

  # === STATUSY ===
  include AASM

  aasm column: :status do
    state :draft, initial: true
    state :created
    state :dispatched
    state :sent
    state :delivered
    state :failed
    state :cancelled

    event :create_parcel do
      transitions from: :draft, to: :created
    end

    event :dispatch do
      transitions from: :created, to: :dispatched
    end

    event :send_parcel do
      transitions from: :dispatched, to: :sent
    end

    event :deliver do
      transitions from: :sent, to: :delivered
    end

    event :fail do
      transitions from: [:created, :dispatched, :sent], to: :failed
    end

    event :cancel do
      transitions from: [:draft, :created, :dispatched], to: :cancelled
    end
  end

  def self.event_for_status(status)
    case status.to_sym
    when :draft then :create_parcel
    when :created then :dispatch
    when :dispatched then :send_parcel
    when :sent then :deliver
    when :failed then :fail
    when :cancelled then :cancel
    else
      nil
    end
  end

  # akcje dostępne dla aktualnego statusu zamówienia
  def status_actions
    case self.status.to_sym
    when :draft
      [ { label: "Utwórz przesyłkę", path: Rails.application.routes.url_helpers.create_parcel_shipment_path(self), method: :post } ]
    when :created
      if tracking_number.present?
        [ { label: "Zamów kuriera", path: Rails.application.routes.url_helpers.create_dispatch_shipment_path(self), method: :post } ]
      end
    else
      []
    end
  end


  # === METODY ===

  # tworznie przesyłki u przewoźnika
  def create_parcel!
    service_class.new(self).create_parcel
  end

  def cancel_parcel!
    service_class.new(self).cancel_parcel
  end

  def track_parcel
    service_class.new(self).track_parcel
  end

  # sprawdzenie statusu przesyłki
  def get_status
    data = service_class.new(self).check_status
    sync_with_provider_data(data)
    data
  end

  # tworzenie zlecenia odbioru 
  def create_dispatch!(comment: nil)
    service_class.new(self).create_dispatch_order(comment: comment)
  end

  def full_address
    return locker_code if delivery_type_locker?

    [
      address_street,
      address_house,
      address_apartment,
      address_city,
      address_postcode,
      address_country
    ].compact.join(', ')
  end

  def mark_as_failed!(error)
    update!(
      status: :failed,
      error_message: error.to_s
    )
  end

  def mark_as_created!(tracking_number:, external_id: nil)
    update!(
      status: :created,
      tracking_number: tracking_number,
      external_id: external_id,
      error_message: nil
    )
  end

  def status_label
    return 'Brak statusu' if status.blank?
    I18n.t("activerecord.attributes.shipment.statuses.#{status}", default: status.humanize)
  end

  private

  def service_class
    "Shipments::#{provider.classify}".constantize
  end

  def set_default_status
    self.status ||= :draft
  end

  def sync_with_provider_data(data)
    return unless data.is_a?(Hash)

    updates = {}
    updates[:tracking_number] = data['tracking_number'] if data['tracking_number'].present? && tracking_number.blank?
    updates[:external_id] = data['id'] if data['id'].present? && external_id.blank?

    update!(updates) if updates.present?
  rescue StandardError => e
    Rails.logger.error("Shipment sync failed: #{e.message}")
  end
end
