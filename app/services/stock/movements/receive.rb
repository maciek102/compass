module Stock
  module Movements
  # Serwis intencyjny do przyjęcia towaru na magazyn
  # Tworzy StockMovement i generuje fizyczne itemy
    class Receive
      class Error < StandardError; end

      # Wywołanie serwisu:
      # Stock::Receive.call(variant: variant, quantity: 10, user: current_user, note: "Dostawa FV/12/2025", cost_prices: {0 => 10.50, 1 => 11.00})
      def self.call(stock_operation:, quantity:, user: nil, note: nil, numbers: {}, cost_prices: {}, general_cost_price: nil, **args)
        new(stock_operation: stock_operation, quantity: quantity, user: user, note: note, numbers: numbers, cost_prices: cost_prices, general_cost_price: general_cost_price).call
      end

      def initialize(stock_operation:, quantity:, user: nil, note: nil, numbers: {}, cost_prices: {}, general_cost_price: nil)
        @stock_operation = stock_operation
        @variant = stock_operation.variant
        @quantity = quantity.to_i
        @user = user
        @note = note
        @numbers = numbers || {}
        @cost_prices = cost_prices || {}
        @general_cost_price = general_cost_price.to_f if general_cost_price.present?
      end

      def call
        validate!

        ActiveRecord::Base.transaction do
          # 1. Tworzymy stock movement
          movement = Stock::Movements::Move.call(
            stock_operation: stock_operation,
            quantity: quantity,
            direction: :in,
            movement_type: "delivery",
            user: user,
            note: note
          )

          # 2. Generujemy fizyczne itemy
          create_items(movement)
        end
      end

      private

      attr_reader :stock_operation, :variant, :quantity, :user, :note, :numbers, :cost_prices, :general_cost_price

      def validate!
        raise Error, "Quantity must be positive" if quantity <= 0
        raise Error, "Variant disabled" if variant.disabled?
      end

      def create_items(movement)
        quantity.times do |index|
          number = numbers[index.to_s].presence || nil
          
          # Ustal cenę zakupu: najpierw specificzna dla itemu, potem ogólna, potem nil
          cost_price = cost_prices[index.to_s].to_f if cost_prices[index.to_s].present?
          cost_price ||= general_cost_price
          
          item = variant.items.create!(
            status: :in_stock,
            number: number,
            cost_price: cost_price
          )

          movement.items << item
        end
      end
    end
  end
end
