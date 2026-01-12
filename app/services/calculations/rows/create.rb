module Calculations
  module Rows
    # Serwis do dodawania nowego wiersza do obliczenia
    # Automatycznie ustawia position jako kolejny
    #
    # Przykład użycia:
    # Calculations::Rows::Create.call(
    #   calculation: calculation,
    #   variant_id: 1,
    #   quantity: 10,
    #   unit_price: 100
    # )
    class Create
      class Error < StandardError; end

      def self.call(**args)
        new(**args).call
      end

      def initialize(calculation:, variant_id: nil, name: nil, description: nil, quantity: 1, unit: 0, unit_price: 0, vat_percent: 23)
        @calculation = calculation
        @variant_id = variant_id
        @name = name
        @description = description
        @quantity = quantity
        @unit = unit
        @unit_price = unit_price
        @vat_percent = vat_percent
      end

      def call
        validate!

        ActiveRecord::Base.transaction do
          create_row!
          recalculate!
        end

        @row
      end

      private

      attr_reader :calculation, :variant_id, :name, :description, :quantity, :unit, :unit_price, :vat_percent, :row

      def validate!
        raise Error, "Calculation is required" unless calculation
        raise Error, "Quantity must be positive" if quantity.to_f <= 0
        raise Error, "Unit price cannot be negative" if unit_price.to_f < 0

        if variant_id.blank? && name.blank?
          raise Error, "Name is required when variant is not specified"
        end
      end

      def create_row!
        next_position = calculation.calculation_rows.maximum(:position).to_i + 1

        row_name = name.presence || variant&.full_name || "Pozycja niestandardowa"

        @row = calculation.calculation_rows.create!(
          variant_id: variant_id,
          position: next_position,
          name: row_name,
          description: description,
          quantity: quantity,
          unit: unit || "szt.",
          unit_price: unit_price,
          vat_percent: vat_percent,
          subtotal: 0,
          total_net: 0,
          total_gross: 0
        )

        log_creation!
      end

      def recalculate!
        Calculations::Rows::Recalculate.call(row: @row)
        Calculations::Recalculate.call(calculation: calculation)
      end

      def variant
        @variant ||= Variant.find_by(id: variant_id) if variant_id.present?
      end

      def log_creation!
        Log.created!(
          loggable: calculation.calculable,
          user: Current.user,
          message: "Wersja ##{calculation.version_number} - dodano nową pozycję: #{row.name}"
        )
      end
    end
  end
end
