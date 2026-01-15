module DashboardWidgets
  class WarehouseStockWidget < DashboardWidget
    def initialize(user:)
      super
      @title = "Stan magazynu"
      @query = Dashboards::WarehouseQuery.new(user: user)
    end

    def data
      @query.stock_stats
    end
    
    def rows
      d = data
      [
        { label: "W magazynie", value: d[:in_stock], klass: "green" },
        { label: "Zarezerwowane", value: d[:reserved], klass: "orange" },
        { label: "Uszkodzone", value: d[:damaged], klass: "red" },
        { label: "Razem", value: d[:total_items] }
      ]
    end
  end
end
