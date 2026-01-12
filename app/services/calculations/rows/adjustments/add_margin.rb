module Calculations
  module Rows
    module Adjustments
      # Serwis do dodawania marży do wiersza
      # Tworzy RowAdjustment typu margin
      #
      # Przykład użycia:
      # Calculations::Rows::Adjustments::AddMargin.call(
      #   row: calculation_row,
      #   amount: 20,
      #   is_percentage: true
      # )
      class AddMargin
        class Error < StandardError; end

        def self.call(**args)
          new(**args).call
        end

        def initialize(row:, amount:, is_percentage: false, description: nil)
          @row = row
          @amount = amount
          @is_percentage = is_percentage
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

        attr_reader :row, :amount, :is_percentage, :description, :adjustment

        def validate!
          raise Error, "Row is required" unless row
          raise Error, "Amount must be positive" if amount.to_f < 0
        end

        def create_adjustment!
          @adjustment = row.row_adjustments.create!(
            adjustment_type: :margin,
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
