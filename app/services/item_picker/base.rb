# Moduł służący jako zbiór polityk i reguł wyboru fizycznych egzemplarzy (Item) z magazynu dla różnych operacji
module ItemPicker

  # Podstawowa klasa bazowa dla wszystkich strategii wyboru itemów
  class Base
    Result = Struct.new(:available_items, :selected_items, :selected_ids)

    def initialize(scope:)
      @scope = scope
    end

    def pick(quantity:)
      raise NotImplementedError
    end

    private

    attr_reader :scope
  end
  
end
