class RowAdjustment < ApplicationRecord
  include Loggable

  belongs_to :calculation_row
  belongs_to :organization

  enum :adjustment_type, { discount: 0, margin: 1 }

  validates :calculation_row_id, presence: true
  validates :adjustment_type, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :name, presence: true

  scope :discounts, -> { where(adjustment_type: :discount) }
  scope :margins, -> { where(adjustment_type: :margin) }

  def computed_amount
    # Jeśli to procent, liczymy od ceny netto wiersza
    if percentage?
      (calculation_row.total_net * amount / 100).round(2)
    else
      amount
    end
  end

  def percentage?
    amount.to_s.include?('%') || (respond_to?(:is_percentage) && is_percentage?)
  end
end
