class AddOrganizationScopedUniquenessConstraints < ActiveRecord::Migration[8.1]
  def change
    remove_index :products, :sku, if_exists: true
    remove_index :products, :code, if_exists: true
    add_index :products, [:organization_id, :sku], unique: true
    add_index :products, [:organization_id, :code], unique: true

    remove_index :product_categories, :slug, if_exists: true
    remove_index :product_categories, :code, if_exists: true
    add_index :product_categories, [:organization_id, :slug], unique: true
    add_index :product_categories, [:organization_id, :code], unique: true

    remove_index :variants, :sku, if_exists: true
    add_index :variants, [:organization_id, :sku], unique: true
    add_index :variants, [:organization_id, :ean], unique: true, if_not_exists: true

    remove_index :items, [:variant_id, :serial_number], if_exists: true
    add_index :items, [:organization_id, :serial_number], unique: true
  end
end
