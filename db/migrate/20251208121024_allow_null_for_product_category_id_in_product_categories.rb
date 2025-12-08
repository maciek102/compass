class AllowNullForProductCategoryIdInProductCategories < ActiveRecord::Migration[8.1]
  def change
    change_column_null :product_categories, :product_category_id, true
  end
end
