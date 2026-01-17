module Dashboard
  module Widgets
    class WarehouseOperationsComponent < WidgetComponent
      def initialize(user:)
        super
        @title = "Operacje"
        @query = Dashboards::WarehouseQuery.new(user: user)
      end

      def data
        @data ||= @query
      end

      def rows
        d = data
        [
          { label: "Otwarte", value: d.open_operations.count, klass: "orange" },
          { label: "W realizacji", value: d.in_realization_operations.count, klass: "green" },
          { label: "Dzisiaj", value: d.todays_operations.count }
        ]
      end
    end
  end
end
