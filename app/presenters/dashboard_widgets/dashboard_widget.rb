module DashboardWidgets
  class DashboardWidget
    attr_reader :title, :partial

    def initialize(user:)
      @user = user
      @title = "Widget"
      @partial = "shared/widgets/info_widget"
    end

    def data
      @data ||= {}
    end

    def rows
      []
    end

    def widget_type
      self.class.name
    end

    private

    def h
      @h ||= ApplicationController.helpers
    end
  end
end
