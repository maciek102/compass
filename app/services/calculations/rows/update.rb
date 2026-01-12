module Calculations
  module Rows
    # Serwis do edycji wiersza w obliczeniu
    # Automatycznie przelicza sumy po zmianie
    #
    # Przykład użycia:
    # Calculations::Rows::Update.call(
    #   row: calculation_row,
    #   quantity: 20,
    #   unit_price: 150
    # )
    class Update
      class Error < StandardError; end

      def self.call(**args)
        new(**args).call
      end

      def initialize(row:, **attributes)
        @row = row
        @attributes = attributes
      end

      def call
        validate!

        ActiveRecord::Base.transaction do
          update_row!
          log_update!
          recalculate!
        end

        @row
      end

      private

      attr_reader :row, :attributes

      def validate!
        raise Error, "Row is required" unless row
        
        if attributes[:quantity].present? && attributes[:quantity].to_f <= 0
          raise Error, "Quantity must be positive"
        end

        if attributes[:unit_price].present? && attributes[:unit_price].to_f < 0
          raise Error, "Unit price cannot be negative"
        end
      end

      def update_row!
        row.update!(attributes)
      end

      def recalculate!
        Calculations::Rows::Recalculate.call(row: row)
        Calculations::Recalculate.call(calculation: row.calculation)
      end

      def log_update!
        Log.updated!(
          loggable: row.calculation.calculable,
          user: Current.user,
          message: "Wersja ##{row.calculation.version_number} - zaktualizowano pozycję: #{row.name}"
        )
      end
    end
  end
end
