module Stock
  module Operations
    class Process
      class Error < StandardError; end

      def self.call(**args)
        new(**args).call
      end

      def initialize(
        stock_operation:,
        action:, # :receive, :issue, :adjust
        quantity:,
        item_ids: [],
        numbers: {},
        cost_prices: {},
        general_cost_price: nil,
        user: nil,
        note: nil
      )
        @stock_operation = stock_operation
        @quantity = quantity.to_i
        @item_ids = item_ids
        @action = action.to_sym
        @user = user
        @note = note
        @numbers = numbers
        @cost_prices = cost_prices || {}
        @general_cost_price = general_cost_price
      end

      def call
        validate_operation!
        validate_quantity!

        ActiveRecord::Base.transaction do
          execute_action
          finalize_operation_if_needed
        end
      end

      # sprawdzenie możliwości wykonania operacji
      def can_execute?
        return false unless stock_operation.open?
        return false if stock_operation.variant.disabled?
        return false if quantity.to_i <= 0
        return false if quantity.to_i > stock_operation.remaining_quantity

        case action
        when :receive
          true
        when :issue
          true
        when :adjust
          true
        else
          false
        end
      end

      private

      attr_reader :stock_operation, :quantity, :item_ids, :action, :user, :note, :picker, :numbers, :cost_prices, :general_cost_price

      # wykonanie odpowiedniej akcji na magazynie
      def execute_action
        service_class = {
          receive: Stock::Movements::Receive,
          issue: Stock::Movements::Issue,
          adjust: Stock::Movements::Adjust
        }[action]

        raise Error, "Unknown action" unless service_class

        call_args = {
          stock_operation: stock_operation,
          quantity: quantity,
          item_ids: item_ids,
          user: user,
          note: note,
          numbers: numbers
        }

        # ceny tylko dla receive
        if action == :receive
          call_args[:cost_prices] = cost_prices
          call_args[:general_cost_price] = general_cost_price
        end

        service_class.call(**call_args)
      end

      # zmiana statusu - zakończenie operacji jeśli ilość pozostała do wykonania wynosi 0
      def finalize_operation_if_needed
        if stock_operation.remaining_quantity <= 0
          stock_operation.update!(
            status: :completed,
            completed_at: Time.current
          )
        end
      end

      # === WALIDACJE ===
      
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
