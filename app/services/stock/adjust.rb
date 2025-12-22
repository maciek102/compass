module Stock
  # Serwis intencyjny do korekty stanu magazynowego
  class Adjust

    def self.call(variant:, quantity:, direction:, **opts)
      Stock::Move.call(
        variant: variant,
        quantity: quantity,
        direction: direction,
        movement_type: "adjustment",
        **opts
      )
    end
    
  end
end
