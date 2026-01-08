module Calculations
  module Rows
    module Adjustments
      # Serwis do dodawania rabatu do wiersza
      # Tworzy RowAdjustment typu discount
      #
      # Przykład użycia:
      # Calculations::Rows::Adjustments::AddDiscount.call(
      #   row: calculation_row,
      #   amount: 10,
      #   is_percentage: true,
      #   name: "Rabat stały 10%"
      # )
      class AddDiscount
        class Error < StandardError; end

        def self.call(**args)
          new(**args).call
        end

        def initialize(row:, amount:, is_percentage: false, name: "Rabat", description: nil)
          @row = row
          @amount = amount
          @is_percentage = is_percentage
          @name = name
          @description = description
        end

        def call
          validate!

          ActiveRecord::Base.transaction do
            create_adjustment!
            recalculate!
          end

          @adjustment
        end

        private

        attr_reader :row, :amount, :is_percentage, :name, :description, :adjustment

        def validate!
          raise Error, "Row is required" unless row
          raise Error, "Amount must be positive" if amount.to_f < 0
          raise Error, "Name is required" if name.blank?

          if is_percentage && amount.to_f > 100
            raise Error, "Percentage discount cannot exceed 100%"
          end
        end

        def create_adjustment!
          @adjustment = row.row_adjustments.create!(
            organization: row.calculation.organization,
            adjustment_type: :discount,
            name: name,
            amount: amount,
            is_percentage: is_percentage,
            description: description
          )
        end

        def recalculate!
          Calculations::Rows::Recalculate.call(row: row)
          Calculations::Recalculate.call(calculation: row.calculation)
        end
      end
    end
  end
end
