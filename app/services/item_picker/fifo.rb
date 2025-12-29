module ItemPicker
  # Strategia wyboru itemów oparta na zasadzie FIFO (First In, First Out), czyli najpierw te, które zostały dodane najwcześniej
  class Fifo < Base

    def pick(quantity:)
      available = scope.order(received_at: :asc)
      selected = available.limit(quantity)
      
      Result.new(
        available_items: available,
        selected_items: selected,
        selected_ids: selected.pluck(:id)
      )
    end

  end
end
