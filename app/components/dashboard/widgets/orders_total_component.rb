module Dashboard
  module Widgets
    class OrdersTotalComponent < WidgetComponent
      def initialize(user:)
        super
        @title = "Łącznie"
        @query = Dashboards::OrdersQuery.new(user: user)
      end

      def data
        @data ||= @query.total_stats
      end

      def rows
        d = data
        [
          { label: "Utworzono", value: d[:count] },
          { label: "Suma netto", value: h.show_price(d[:sales_net]) },
          { label: "Suma brutto", value: h.show_price(d[:sales_gross]) }
        ]
      end
    end
  end
end
