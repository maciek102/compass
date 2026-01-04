module ImportExport
  module Configs
    # Konfiguracja importu/eksportu dla kategorii produktów
    class ProductCategoryConfig < Base
      def initialize
        super

        # Model, do którego importujemy/eksportujemy
        model ProductCategory
        # Po czym identyfikujemy rekord (unikalność)
        identify_by :organization_id, :name

        # Atrybuty, które będą masowo przypisywane
        attributes(
          :name,
          :description,
          :position,
          :parent_name
        )

        # Mapowanie atrybutu parent_name na product_category_id
        map_attribute :parent_name do |value, record, org|
          if value.present?
            parent = ProductCategory.find_by!(organization_id: org.id, name: value, disabled: false)
            record.product_category_id = parent.id
          else
            record.product_category_id = nil
          end
        end
      end
    end
  end
end
