class AddIdByOrgToMultiTenacy < ActiveRecord::Migration[8.1]
  TABLES = %i[
    product_categories
    products
    variants
    items
    stock_operations
    stock_movements
  ].freeze

  def up
    TABLES.each do |table|
      add_column table, :id_by_org, :integer
      add_index table, [:organization_id, :id_by_org], unique: true, name: "index_#{table}_on_org_and_id_by_org"
      change_column_null table, :id_by_org, false
    end
  end

  def down
    TABLES.each do |table|
      remove_index table, name: "index_#{table}_on_org_and_id_by_org"
      remove_column table, :id_by_org
    end
  end
end
