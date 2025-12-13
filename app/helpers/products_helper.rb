module ProductsHelper
  def display_filters_value(field_name, value)
    return if value.blank?

    relations = [:brand, :category]
    relation_fields = relations.flat_map { |f| ["#{f}_id_eq", "#{f}_id_in"] }

    case field_name.to_s
    when "price_gteq"
      "> #{number_to_currency(value, unit: 'PLN', format: '%n %u', precision: 2)}"
    when "price_lteq"
      "< #{number_to_currency(value, unit: 'PLN', format: '%n %u', precision: 2)}"
    when "s"
      value == "price asc"  ? "Cena rosnąco" :
      value == "price desc" ? "Cena malejąco" :
      value ==  "price_for_sort asc" ? "Cena malejąco" :
      value ==  "price_for_sort desc" ? "Cena rosnąco" : value

    when "bestsellers"
      "Bestsellery"
    when "sales"
      "Wyprzedaże"
    when "individual_category_id_eq"
      category = IndividualCategory.find_by(id: value)
      category&.name || "Kategoria indywidualna"
    when *relation_fields
      relation_class = field_name.to_s.sub(/_id_(eq|in)\z/, "").classify.safe_constantize
      ids = Array.wrap(value).reject(&:blank?)

      return if relation_class.nil? || ids.empty?

      if relation_class == Category
        cats = Category.where(id: ids).includes(:parent_category)

        if ids.size > 1
          cats.map { |c| c.parent_category&.name || c.name }.compact.uniq.join(", ")
        else
          cat = cats.first
          [cat&.parent_category&.name, cat&.name].compact.join(" / ")
        end
      else
        relation_class.where(id: ids).pluck(:name).join(", ")
      end
    when "price_for_sort asc"
      "Cena"
    else
      value
    end
  end

  def remove_product_filter_link(field)
    params.permit(q: Product::PRODUCTS_FILTERS).merge(q: params.permit(q: Product::PRODUCTS_FILTERS)[:q].except(field)).to_enum.to_h
  end

end
