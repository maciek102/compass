class StockOperation < ApplicationRecord
  belongs_to :variant
  belongs_to :user, optional: true

  has_many :stock_movements, dependent: :destroy

  enum :direction, {
    receive: "receive",
    issue: "issue"
  }

  enum :status, {
    open: "open",
    completed: "completed",
    cancelled: "cancelled"
  }

  validates :direction, presence: true
  validates :status, presence: true
  validates :quantity, numericality: { greater_than: 0 }

  # === CALLBACKI ===
  before_validation :set_default_status, on: :create

  # === METODY ===

  def self.icon
    "database"
  end

  # tytuł do wyświetlenia
  def title
    "##{id}"
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

  private

  def set_default_status
    self.status ||= :open
  end
end
