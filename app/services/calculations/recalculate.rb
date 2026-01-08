module Calculations
  # Serwis do przeliczania wszystkich total w Calculation
  # Iteruje przez wszystkie wiersze, przelicza je i sumuje
  #
  # Przykład użycia:
  # Calculations::Recalculate.call(calculation: calculation)
  class Recalculate
    class Error < StandardError; end

    def self.call(**args)
      new(**args).call
    end

    def initialize(calculation:)
      @calculation = calculation
    end

    def call
      validate!

      ActiveRecord::Base.transaction do
        recalculate_rows!
        recalculate_totals!
      end

      @calculation
    end

    private

    attr_reader :calculation

    def validate!
      raise Error, "Calculation is required" unless calculation
    end

    def recalculate_rows!
      calculation.calculation_rows.each do |row|
        Calculations::Rows::Recalculate.call(row: row)
      end
    end

    def recalculate_totals!
      rows = calculation.calculation_rows.reload

      total_net = rows.sum(&:total_net)
      total_vat = rows.sum { |r| r.total_gross - r.total_net }
      total_gross = rows.sum(&:total_gross)

      # Sumujemy rabaty i marże z RowAdjustments
      total_discounts = calculation.row_adjustments.discounts.sum do |adj|
        adj.is_percentage ? (adj.calculation_row.subtotal * adj.amount / 100) : adj.amount
      end

      total_margins = calculation.row_adjustments.margins.sum do |adj|
        adj.is_percentage ? (adj.calculation_row.subtotal * adj.amount / 100) : adj.amount
      end

      calculation.update!(
        total_net: total_net,
        total_vat: total_vat,
        total_gross: total_gross,
        total_discounts: total_discounts,
        total_margins: total_margins
      )
    end
  end
end
