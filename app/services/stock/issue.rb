module Stock
  # Serwis intencyjny do wydania towaru z magazynu
  class Issue
    def self.call(variant:, quantity:, **opts)
      Stock::Move.call(
        variant: variant,
        quantity: quantity,
        direction: :out,
        movement_type: "issue",
        **opts
      )
    end
  end
end
