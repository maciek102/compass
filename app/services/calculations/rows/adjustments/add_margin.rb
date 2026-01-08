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
      #   is_percentage: true,
      #   name: "Marża handlowa 20%"
      # )
      class AddMargin
        class Error < StandardError; end

        def self.call(**args)
          new(**args).call
        end

        def initialize(row:, amount:, is_percentage: false, name: "Marża", description: nil)
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
        end

        def create_adjustment!
          @adjustment = row.row_adjustments.create!(
            organization: row.calculation.organization,
            adjustment_type: :margin,
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
