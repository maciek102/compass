module Calculations
  module Rows
    # Serwis do usuwania wiersza z obliczenia
    # Automatycznie przelicza sumy po usunięciu
    #
    # Przykład użycia:
    # Calculations::Rows::Destroy.call(row: calculation_row)
    class Destroy
      class Error < StandardError; end

      def self.call(**args)
        new(**args).call
      end

      def initialize(row:)
        @row = row
        @calculation = row.calculation
      end

      def call
        validate!

        ActiveRecord::Base.transaction do
          destroy_row!
          recalculate!
        end

        true
      end

      private

      attr_reader :row, :calculation

      def validate!
        raise Error, "Row is required" unless row
      end

      def destroy_row!
        row.destroy!
      end

      def recalculate!
        Calculations::Recalculate.call(calculation: calculation)
      end
    end
  end
end
