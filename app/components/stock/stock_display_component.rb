module Stock
  
  # === StockDisplayComponent ===
  # Komponent do wyświetlania stanu magazynowego wariantu produktu, z opcjonalnym wskazaniem potrzebnej ilości (np w kalkulacji)
  #
  # locals:
  # variant: obiekt wariantu produktu
  # needed_quantity: ilość potrzebna (opcjonalnie)
     
    class StockDisplayComponent < ViewComponent::Base
      
      def initialize(variant:, needed_quantity: nil)
        @variant = variant
        @needed_quantity = needed_quantity.to_i if needed_quantity.present?
      end

      def render?
        @variant.present?
      end

      private

      def indicator
        if @needed_quantity.present? && @variant.current_stock < @needed_quantity
          content_tag(:i, "", class: "fa fa-exclamation-triangle", style: "color: red;")
        else
          content_tag(:i, "", class: "fa fa-check-circle", style: "color: green;")
        end
      end

      def display_value
        if @needed_quantity.present?
          "#{@variant.current_stock} / #{@needed_quantity}"
        else
          @variant.current_stock
        end
      end
  
    end

end