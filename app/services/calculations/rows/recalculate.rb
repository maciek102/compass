module Calculations
  module Rows
    # Serwis do przeliczania sum w pojedynczym wierszu
    # Uwzględnia wszystkie RowAdjustments (rabaty i marże)
    #
    # Przykład użycia:
    # Calculations::Rows::Recalculate.call(row: calculation_row)
    class Recalculate
      class Error < StandardError; end

      def self.call(**args)
        new(**args).call
      end

      def initialize(row:)
        @row = row
      end

      def call
        validate!

        calculate_subtotal!
        apply_adjustments!
        apply_vat!
        save_row!

        @row
      end

      private

      attr_reader :row

      def validate!
        raise Error, "Row is required" unless row
      end

      def calculate_subtotal!
        @subtotal = (row.quantity.to_f * row.unit_price.to_f).round(2)
      end

      def apply_adjustments!
        # Rozpoczynamy od subtotal
        @total_net = @subtotal

        # Obliczamy rabaty
        discounts = row.row_adjustments.discounts
        @total_discounts = discounts.sum do |adj|
          if adj.is_percentage
            (@subtotal * adj.amount / 100).round(2)
          else
            adj.amount.to_f
          end
        end

        # Odejmujemy rabaty
        @total_net -= @total_discounts

        # Obliczamy marże
        margins = row.row_adjustments.margins
        @total_margins = margins.sum do |adj|
          if adj.is_percentage
            (@subtotal * adj.amount / 100).round(2)
          else
            adj.amount.to_f
          end
        end

        # Dodajemy marże
        @total_net += @total_margins

        # Upewnij się, że total_net nie jest ujemny
        @total_net = [@total_net, 0].max
      end

      def apply_vat!
        vat_rate = row.vat_percent.to_f / 100
        @total_vat = (@total_net * vat_rate).round(2)
        @total_gross = (@total_net + @total_vat).round(2)
      end

      def save_row!
        if row.new_record?
          row.subtotal = @subtotal
          row.total_net = @total_net
          row.total_gross = @total_gross
        else
          row.update_columns(
            subtotal: @subtotal,
            total_net: @total_net,
            total_gross: @total_gross
          )
        end
      end
    end
  end
end
