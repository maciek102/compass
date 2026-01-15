module Dashboards
  class OrdersQuery
    def initialize(user:)
      @user = user
    end

    # dzisiejsze statystyki
    def today_stats
      calculations_for_orders(orders_today)
    end

    def weekly_stats
      calculations_for_orders(orders_this_week)
    end

    def total_stats
      calculations_for_orders(base_scope)
    end

    # ostatnie zamówienia
    def latest_orders(limit: 5)
      base_scope.recent.limit(limit)
    end

    # oczekujące zamówienia
    def pending_orders
      base_scope.pending
    end

    private

    def calculations_for_orders(orders)
      current_calcs = Calculation.where(calculable: orders, is_current: true)

      {
        count: orders.count,
        sales_net: current_calcs.sum(:total_net) || 0,
        sales_gross: current_calcs.sum(:total_gross) || 0
      }
    end

    def orders_today
      base_scope.where(created_at: Time.zone.today.all_day)
    end

    def orders_this_week
      base_scope.where(created_at: Time.zone.now.beginning_of_week..Time.zone.now.end_of_week)
    end

    def base_scope
      Order.all
    end
  end
end
