module ItemPicker
  # Strategia wyboru itemów oparta na zasadzie FEFO (First Expired, First Out), czyli najpierw te, które mają najwcześniejszą datę ważności
  class Fefo < Base

    # EXPIRES AT - JESZCZE NIE ZAIMPLEMENTOWANE
    def pick(quantity:)
      available = scope.where.not(expires_at: nil).order(expires_at: :asc)
      selected = available.limit(quantity)

      Result.new(
        available_items: available,
        selected_items: selected,
        selected_ids: selected.pluck(:id)
      )
    end
    
  end
end
