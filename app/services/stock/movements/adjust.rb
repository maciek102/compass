module Stock
  module Movements
    # Serwis intencyjny do korekty stanu magazynowego
    class Adjust

      def self.call(stock_operation:, quantity:, direction:, **opts)
        Stock::Movements::Move.call(
          stock_operation: stock_operation,
          quantity: quantity,
          direction: direction,
          movement_type: "adjustment",
          **opts
        )
      end
      
    end
  end
end
