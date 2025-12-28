class CreateStockOperations < ActiveRecord::Migration[8.1]
  def change
    create_table :stock_operations do |t|
      t.references :variant, null: false, foreign_key: true
      t.string :direction
      t.integer :quantity
      t.string :status
      t.references :user, foreign_key: true
      t.text :note

      t.datetime :completed_at

      t.timestamps
    end
  end
end
