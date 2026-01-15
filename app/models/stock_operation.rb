class StockOperation < ApplicationRecord
  include Tenantable
  include Loggable
  include OrganizationScoped

  belongs_to :organization
  belongs_to :variant
  belongs_to :user, optional: true
  belongs_to :calculation, optional: true

  has_many :stock_movements, dependent: :destroy

  enum :direction, {
    receive: "receive",
    issue: "issue"
  }

  enum :status, {
    open: "open",
    in_progress: "in_progress",
    completed: "completed",
    cancelled: "cancelled"
  }

  FILTERS = [
    :id_by_org_eq,
    :variant_sku_cont,
    :status_eq,
    :direction_eq,
    :code_cont
  ].freeze

  # === SCOPE ===
  scope :recent, -> { order(created_at: :desc) }

  # === WALIDACJE ===
  validates :direction, presence: true
  validates :status, presence: true
  validates :quantity, numericality: { greater_than: 0 }

  # === CALLBACKI ===
  before_validation :set_default_status, on: :create




  # === METODY ===
   
  def self.for_user(user)
    all
  end

  def self.icon
    "database"
  end

  # tytuł do wyświetlenia
  def title
    "##{id_by_org} - #{variant.product.name} / #{variant.name}"
  end

  def short_title
    "##{id_by_org}"
  end

  def status_color
    color = case status
    when "open"
      "gray"
    when "in_progress"
      "orange"
    when "completed"
      "green"
    when "cancelled"
      "red"
    else
      "yellow"
    end

    "background-color: #{color};"
  end

  def status_label
    I18n.t("activerecord.attributes.stock_operation.statuses.#{status}")
  end

  def completed_quantity
    stock_movements.sum(:quantity)
  end

  def remaining_quantity
    quantity - completed_quantity
  end

  # stan wykonania
  def quantity_finished
    "#{completed_quantity} / #{quantity}"
  end

  def can_accept_movement?(quantity)
    return false if completed?
    quantity.to_i <= remaining_quantity
  end

  def complete!
    update!(
      status: :completed,
      completed_at: Time.current
    )
  end

  def cancel!
    update!(status: :cancelled)
  end

  # Guard logic – do użycia w serwisach
  def validate_movement!(quantity)
    raise Error, "Operation already completed" if completed?
    raise Error, "Quantity exceeds required amount" if quantity > remaining_quantity
  end

  def self.quick_search
    :variant_sku_or_variant_name_or_variant_product_name_cont
  end

  private

  def set_default_status
    self.status ||= :open
  end

  def self.ransackable_attributes(auth_object = nil)
    ["completed_at", "created_at", "direction", "id_by_org", "note", "quantity", "status", "updated_at", "user_id", "variant_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["stock_movements", "user", "variant"]
  end
end
