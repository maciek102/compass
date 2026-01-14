class AddReservedStockOperationToItems < ActiveRecord::Migration[8.1]
  def change
    add_reference :items, :reserved_stock_operation, foreign_key: { to_table: :stock_operations }
  end
end