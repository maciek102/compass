module Stock
  # Serwis intencyjny do wydania towaru z magazynu
  class Issue
    class Error < StandardError; end

    def self.call(variant:, quantity:, picker:, user: nil, note: nil)
      new(variant: variant, quantity: quantity, picker: picker, user: user, note: note).call
    end

    def initialize(variant:, quantity:, picker:, user: nil, note: nil)
      @variant = variant
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
        movement = Stock::Move.call(
          variant: variant,
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

    attr_reader :variant, :quantity, :picker, :user, :note, :items

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
