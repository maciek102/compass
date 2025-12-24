module ItemPicker
  # Strategia ręcznego wyboru itemów na podstawie podanych ID
  class Manual < Base

    def initialize(scope:, item_ids:)
      super(scope: scope)
      @item_ids = item_ids
    end

    def pick(quantity:)
      scope.where(id: @item_ids).limit(quantity)
    end
    
  end
end
