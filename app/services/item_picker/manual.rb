module ItemPicker
  # Strategia ręcznego wyboru itemów na podstawie podanych ID
  class Manual < Base

    def initialize(scope:, item_ids:)
      super(scope: scope)
      @item_ids = item_ids
    end

    def pick(quantity:)
      available = scope
      selected = available.where(id: @item_ids).limit(quantity)
      
      Result.new(
        available_items: available,
        selected_items: selected,
        selected_ids: selected.pluck(:id)
      )
    end
    
  end
end
