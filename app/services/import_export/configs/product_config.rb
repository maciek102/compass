module ImportExport
  module Configs
    # Konfiguracja importu/eksportu dla produktów
    class ProductConfig < Base
      def initialize
        super

        model Product
        identify_by :organization_id, :code

        attributes(
          :id_by_org,
          :code,
          :name,
          :sku,
          :slug,
          :description,
          :status,
          :disabled
        )

        belongs_to :product_category,
          column: :category_code,
          lookup: ->(org, value) {
            ProductCategory.find_by!(
              organization_id: org.id,
              code: value,
              disabled: false # tylko nieusunięte
            )
          }
      end
    end
  end
end
