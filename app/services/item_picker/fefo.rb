module ItemPicker
  # Strategia wyboru itemów oparta na zasadzie FEFO (First Expired, First Out), czyli najpierw te, które mają najwcześniejszą datę ważności
  class FEFO < Base

    def pick(quantity:)
      scope
        .where.not(expires_at: nil)
        .order(expires_at: :asc)
        .limit(quantity)
    end
    
  end
end
