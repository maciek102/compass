class LinkCalculationsToStockOperations < ActiveRecord::Migration[8.1]
  def change
    add_column :calculations, :confirmed_at, :datetime
    add_reference :stock_operations, :calculation, foreign_key: true
  end
end
