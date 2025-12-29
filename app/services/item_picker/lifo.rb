module ItemPicker
  # Strategia wyboru itemów oparta na zasadzie LIFO (Last In, First Out), czyli najpierw te, które zostały dodane najpóźniej
  class Lifo < Base

    def pick(quantity:)
      scope
        .order(received_at: :desc).limit(quantity)
    end

  end
end