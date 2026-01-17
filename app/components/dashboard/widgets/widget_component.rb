module Dashboard
  module Widgets
    # Base dashboard widget component providing common helpers and default rendering
    class WidgetComponent < ViewComponent::Base
      attr_reader :title, :user

      def initialize(user:)
        @user = user
        @title = "Widget"
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

      def call
        render "shared/widgets/info_widget", widget: self
      end

      private

      def h
        helpers
      end
    end
  end
end
