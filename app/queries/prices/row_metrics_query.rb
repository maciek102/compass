module Prices
  class RowMetricsQuery
    def initialize(row:)
      @row = row
    end

    def call
      return {} unless @row.standard? && @row.variant
      return {} if cost_price.blank?

      metrics_hash
    end
    

    private

    def variant
      @row.variant
    end

    def cost_price
      # Używaj average_cost_price z wariantu (obliczonej na podstawie itemów)
      variant.average_cost_price
    end

    def selling_price
      @row.unit_price
    end

    def quantity
      @row.quantity
    end

    def unit_profit
      selling_price - cost_price.to_f
    end

    def total_profit
      unit_profit * quantity
    end

    # procent marży
    def margin_percent
      selling_price > 0 ? ((selling_price - cost_price.to_f) / selling_price * 100) : 0
    end

    # procent narzutu
    def markup_percent
      cost_price.to_f > 0 ? ((selling_price - cost_price.to_f) / cost_price.to_f * 100) : 0
    end

    def metrics_hash
      {
        cost_price: cost_price,
        selling_price: selling_price,
        quantity: quantity,
        unit_profit: unit_profit,
        total_profit: total_profit,
        margin_percent: margin_percent,
        markup_percent: markup_percent,
        total_cost: cost_price.to_f * quantity,
        total_selling_value: selling_price * quantity
      }
    end

  end
end