module Stock
  # Serwis intencyjny do przyjęcia towaru na magazyn
  # Tworzy StockMovement i generuje fizyczne itemy
  class Receive
    class Error < StandardError; end

    # Wywołanie serwisu:
    # Stock::Receive.call(variant: variant, quantity: 10, user: current_user, note: "Dostawa FV/12/2025")
    def self.call(variant:, quantity:, user: nil, note: nil)
      new(variant: variant, quantity: quantity, user: user, note: note).call
    end

    def initialize(variant:, quantity:, user: nil, note: nil)
      @variant = variant
      @quantity = quantity.to_i
      @user = user
      @note = note
    end

    def call
      validate!

      ActiveRecord::Base.transaction do
        # 1. Tworzymy stock movement
        Stock::Move.call(
          variant: variant,
          quantity: quantity,
          direction: :in,
          movement_type: "delivery",
          user: user,
          note: note
        )

        # 2. Generujemy fizyczne itemy
        create_items
      end
    end

    private

    attr_reader :variant, :quantity, :user, :note

    def validate!
      raise Error, "Quantity must be positive" if quantity <= 0
      raise Error, "Variant disabled" if variant.disabled?
    end

    def create_items
      quantity.times do
        variant.items.create!(
          status: :in_stock
          # opcjonalnie: serial_number, batch, expires_at, custom_attributes
        )
      end
    end
  end
end
