class CreateRowAdjustments < ActiveRecord::Migration[8.1]
  def change
    create_table :row_adjustments do |t|
      t.references :calculation_row, null: false, foreign_key: true

      t.integer :adjustment_type, null: false, default: 0

      t.decimal :amount, precision: 12, scale: 2, null: false, default: 0
      t.boolean :is_percentage, default: false

      t.text :description

      t.timestamps
    end

    add_index :row_adjustments, :adjustment_type
    add_index :row_adjustments, [:calculation_row_id, :adjustment_type]
  end
end
