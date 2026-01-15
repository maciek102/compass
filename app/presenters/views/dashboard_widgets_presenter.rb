module Views
  class DashboardWidgetsPresenter
    include IconsHelper
    
    attr_reader :user

    def initialize(user:)
      @user = user
    end

    def build
      return [] unless user

      sections
    end

    private

    # sekcje dashboardu
    def sections
      [
        {
          title: "Zamówienia",
          widgets: [
            DashboardWidgets::OrdersTodayWidget.new(user: user),
            DashboardWidgets::OrdersThisWeekWidget.new(user: user),
            DashboardWidgets::OrdersTotalWidget.new(user: user)
          ]
        },
        {
          title: "Magazyn",
          widgets: [
            DashboardWidgets::WarehouseOperationsWidget.new(user: user),
            DashboardWidgets::WarehouseStockWidget.new(user: user)
          ]
        }
      ]
    end
    
  end
end