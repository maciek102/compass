module ItemPicker
  # Strategia wyboru itemów oparta na zasadzie FIFO (First In, First Out), czyli najpierw te, które zostały dodane najwcześniej
  class FIFO < Base

    def pick(quantity:)
      scope
        .order(created_at: :asc).limit(quantity)
    end

  end
end
