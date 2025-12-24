class CreateStockMovementItems < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_movement_items do |t|
      t.references :stock_movement, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true

      t.timestamps
    end
  end
end
