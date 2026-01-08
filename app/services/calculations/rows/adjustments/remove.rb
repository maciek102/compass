module Calculations
  module Rows
    module Adjustments
      # Serwis do usuwania adjustmentu (rabatu lub marży)
      # Automatycznie przelicza sumy po usunięciu
      #
      # Przykład użycia:
      # Calculations::Rows::Adjustments::Remove.call(adjustment: row_adjustment)
      class Remove
        class Error < StandardError; end

        def self.call(**args)
          new(**args).call
        end

        def initialize(adjustment:)
          @adjustment = adjustment
          @row = adjustment.calculation_row
        end

        def call
          validate!

          ActiveRecord::Base.transaction do
            destroy_adjustment!
            recalculate!
          end

          true
        end

        private

        attr_reader :adjustment, :row

        def validate!
          raise Error, "Adjustment is required" unless adjustment
        end

        def destroy_adjustment!
          adjustment.destroy!
        end

        def recalculate!
          Calculations::Rows::Recalculate.call(row: row)
          Calculations::Recalculate.call(calculation: row.calculation)
        end
      end
    end
  end
end
