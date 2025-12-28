module Stock
  module Operations
    class Process
      class Error < StandardError; end

      def self.call(**args)
        new(**args).call
      end

      def initialize(
        stock_operation:,
        quantity:,
        action:, # :receive, :issue, :adjust
        user: nil,
        note: nil,
        picker: nil
      )
        @stock_operation = stock_operation
        @quantity = quantity.to_i
        @action = action.to_sym
        @user = user
        @note = note
        @picker = picker
      end

      def call
        validate_operation!
        validate_quantity!

        ActiveRecord::Base.transaction do
          execute_action
          finalize_operation_if_needed
        end
      end

      private

      attr_reader :stock_operation, :quantity, :action, :user, :note, :picker

      def execute_action
        service_class = {
          receive: Stock::Movements::Receive,
          issue: Stock::Movements::Issue,
          adjust: Stock::Movements::Adjust
        }[action]

        raise Error, "Unknown action" unless service_class

        service_class.call(
          stock_operation: stock_operation,
          quantity: quantity,
          user: user,
          note: note
        )
      end

      def finalize_operation_if_needed
        if stock_operation.remaining_quantity <= 0
          stock_operation.update!(
            status: :completed,
            completed_at: Time.current
          )
        end
      end

      def validate_operation!
        raise Error, "StockOperation is not open" unless stock_operation.open?
        raise Error, "Variant disabled" if stock_operation.variant.disabled?
      end

      def validate_quantity!
        raise Error, "Quantity must be positive" if quantity <= 0
        raise Error, "Quantity exceeds required amount" if quantity > stock_operation.remaining_quantity
      end
    end
  end
end
