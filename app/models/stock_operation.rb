class StockOperation < ApplicationRecord
  include Tenantable
  include Loggable
  include OrganizationScoped

  belongs_to :organization
  belongs_to :variant
  belongs_to :user, optional: true

  has_many :stock_movements, dependent: :destroy

  has_many :logs, as: :loggable, dependent: :destroy # historia zmian

  enum :direction, {
    receive: "receive",
    issue: "issue"
  }

  enum :status, {
    open: "open",
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
    when "completed"
      "green"
    when "cancelled"
      "red"
    else
      "yellow"
    end

    "background-color: #{color};"
  end

  def completed_quantity
    stock_movements.sum(:quantity)
  end

  def remaining_quantity
    quantity - completed_quantity
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
