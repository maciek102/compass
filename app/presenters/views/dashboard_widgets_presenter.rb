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
            Dashboard::Widgets::OrdersTodayComponent.new(user: user),
            Dashboard::Widgets::OrdersThisWeekComponent.new(user: user),
            Dashboard::Widgets::OrdersTotalComponent.new(user: user)
          ]
        },
        {
          title: "Magazyn",
          widgets: [
            Dashboard::Widgets::WarehouseOperationsComponent.new(user: user),
            Dashboard::Widgets::WarehouseStockComponent.new(user: user)
          ]
        }
      ]
    end
    
  end
end