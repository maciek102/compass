class AddOrganizationMultiTenancy < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :organization_id, :bigint, if_not_exists: true
    add_index :users, :organization_id, if_not_exists: true
    
    add_column :product_categories, :organization_id, :bigint, if_not_exists: true
    add_index :product_categories, :organization_id, if_not_exists: true
    
    add_column :products, :organization_id, :bigint, if_not_exists: true
    add_index :products, :organization_id, if_not_exists: true
    
    add_column :variants, :organization_id, :bigint, if_not_exists: true
    add_index :variants, :organization_id, if_not_exists: true
    
    add_column :items, :organization_id, :bigint, if_not_exists: true
    add_index :items, :organization_id, if_not_exists: true
    
    add_column :stock_operations, :organization_id, :bigint, if_not_exists: true
    add_index :stock_operations, :organization_id, if_not_exists: true
    
    add_column :stock_movements, :organization_id, :bigint, if_not_exists: true
    add_index :stock_movements, :organization_id, if_not_exists: true
    
    ActsAsTenant.without_tenant do
      unless Organization.exists?
        default_org = Organization.create!(
          name: "Default Organization",
          description: "Default organization for existing data"
        )
      else
        default_org = Organization.first
      end
      
      User.where(organization_id: nil).update_all(organization_id: default_org.id)
      ProductCategory.where(organization_id: nil).update_all(organization_id: default_org.id)
      Product.where(organization_id: nil).update_all(organization_id: default_org.id)
      Variant.where(organization_id: nil).update_all(organization_id: default_org.id)
      Item.where(organization_id: nil).update_all(organization_id: default_org.id)
      StockOperation.where(organization_id: nil).update_all(organization_id: default_org.id)
      StockMovement.where(organization_id: nil).update_all(organization_id: default_org.id)
    end
    
    change_column_null :users, :organization_id, false
    change_column_null :product_categories, :organization_id, false
    change_column_null :products, :organization_id, false
    change_column_null :variants, :organization_id, false
    change_column_null :items, :organization_id, false
    change_column_null :stock_operations, :organization_id, false
    change_column_null :stock_movements, :organization_id, false
    
    add_foreign_key :users, :organizations, if_not_exists: true
    add_foreign_key :product_categories, :organizations, if_not_exists: true
    add_foreign_key :products, :organizations, if_not_exists: true
    add_foreign_key :variants, :organizations, if_not_exists: true
    add_foreign_key :items, :organizations, if_not_exists: true
    add_foreign_key :stock_operations, :organizations, if_not_exists: true
    add_foreign_key :stock_movements, :organizations, if_not_exists: true
  end
  
  def down
    remove_foreign_key :stock_movements, :organizations, if_exists: true
    remove_foreign_key :stock_operations, :organizations, if_exists: true
    remove_foreign_key :items, :organizations, if_exists: true
    remove_foreign_key :variants, :organizations, if_exists: true
    remove_foreign_key :products, :organizations, if_exists: true
    remove_foreign_key :product_categories, :organizations, if_exists: true
    remove_foreign_key :users, :organizations, if_exists: true
    
    remove_index :stock_movements, :organization_id, if_exists: true
    remove_column :stock_movements, :organization_id
    
    remove_index :stock_operations, :organization_id, if_exists: true
    remove_column :stock_operations, :organization_id
    
    remove_index :items, :organization_id, if_exists: true
    remove_column :items, :organization_id
    
    remove_index :variants, :organization_id, if_exists: true
    remove_column :variants, :organization_id
    
    remove_index :products, :organization_id, if_exists: true
    remove_column :products, :organization_id
    
    remove_index :product_categories, :organization_id, if_exists: true
    remove_column :product_categories, :organization_id
    
    remove_index :users, :organization_id, if_exists: true
    remove_column :users, :organization_id
  end
end