module ItemPicker
  # Strategia wyboru itemów oparta na zasadzie LIFO (Last In, First Out), czyli najpierw te, które zostały dodane najpóźniej
  class Lifo < Base

    def pick(quantity:)
      available = scope.order(received_at: :desc)
      selected = available.limit(quantity)

      Result.new(
        available_items: available,
        selected_items: selected,
        selected_ids: selected.pluck(:id)
      )
    end

  end
end