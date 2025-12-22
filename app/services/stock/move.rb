module Stock
  # Usługa obsługująca ruchy magazynowe (przyjęcia/wydań)
  # Silnik do tworzenia ruchu magazynowego z walidacjami i aktualizacją stanu magazynowego wariantu 
  # Jest to jedyna brama do zmiany stanu magazynu
  # Zmienia stock, tworzy StockMovement, robi transakcję, waliduje reguły, pilnuje spójności
  class Move
    class Error < StandardError; end

    def self.call(**args)
      new(**args).call
    end

    def initialize(variant:, quantity:, direction:, movement_type:, user: nil, note: nil)
      @variant = variant
      @quantity = quantity.to_i
      @direction = direction.to_s
      @movement_type = movement_type
      @user = user
      @note = note
    end

    def call
      validate!

      ActiveRecord::Base.transaction do
        create_stock_movement
      end
    end

    private

    attr_reader :variant, :quantity, :direction, :movement_type, :user, :note

    def validate!
      raise Error, "Quantity must be positive" if quantity <= 0
      raise Error, "Variant disabled" if variant.disabled?
      raise Error, "Invalid direction" unless %w[in out].include?(direction)

      if direction == "out" && variant.stock.to_i < quantity
        raise Error, "Insufficient stock"
      end
    end

    def create_stock_movement
      StockMovement.create!(
        variant: variant,
        quantity: quantity,
        direction: direction,
        movement_type: movement_type,
        user: user,
        note: note
      )

      # przeliczenie stock wariantu odbywa się w modelu po zapisaniu StockMovement
    end
  end
end
