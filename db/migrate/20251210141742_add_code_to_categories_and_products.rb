class AddCodeToCategoriesAndProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :product_categories, :code, :string
    add_column :products, :code, :string

    add_index :product_categories, :code, unique: true
    add_index :products, :code, unique: true
    add_index :products, :sku, unique: true
  end
end
