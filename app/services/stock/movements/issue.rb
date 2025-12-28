module Stock
  module Movements
    # Serwis intencyjny do wydania towaru z magazynu
    class Issue
      class Error < StandardError; end

      def self.call(stock_operation:, quantity:, picker:, user: nil, note: nil)
        new(stock_operation: stock_operation, quantity: quantity, picker: picker, user: user, note: note).call
      end

      def initialize(stock_operation:, quantity:, picker:, user: nil, note: nil)
        @stock_operation = stock_operation
        @variant = stock_operation.variant
        @quantity = quantity.to_i
        @picker = picker
        @user = user
        @note = note
      end

      def call
        validate!

        @items = picker.pick(quantity: quantity)

        validate_items!

        ActiveRecord::Base.transaction do
          # 1. Tworzymy stock movement
          movement = Stock::Movements::Move.call(
            stock_operation: stock_operation,
            quantity: quantity,
            direction: :out,
            movement_type: "issue",
            user: user,
            note: note
          )

          # 2. Wydajemy fizyczne itemy
          issue_items(movement)
        end
      end
      

      private

      attr_reader :stock_operation, :variant, :quantity, :picker, :user, :note, :items

      def validate!
        raise Error, "Quantity must be positive" if quantity <= 0
        raise Error, "Variant disabled" if variant.disabled?
      end

      def validate_items!
        raise Error, "Not enough stock" if items.size < quantity
      end

      def issue_items(movement)
        items.each do |item|
          item.update!(status: :issued)
          movement.items << item
        end
      end

    end
  end
end
