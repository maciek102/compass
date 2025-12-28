class ChangeStockMovementsRelation < ActiveRecord::Migration[8.1]
  def change
    remove_reference :stock_movements, :variant, foreign_key: true

    add_reference :stock_movements, :stock_operation, null: false, foreign_key: true
  end
end
