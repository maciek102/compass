class CreateCalculationRows < ActiveRecord::Migration[8.1]
  def change
    create_table :calculation_rows do |t|
      t.references :calculation, null: false, foreign_key: true

      t.references :variant, foreign_key: true

      t.integer :position

      t.string :name, null: false
      t.text :description

      t.decimal :quantity, precision: 12, scale: 2, null: false, default: 1
      t.string :unit

      t.decimal :unit_price, precision: 12, scale: 2, default: 0

      t.decimal :vat_percent, precision: 5, scale: 2, default: 0

      t.decimal :subtotal, precision: 12, scale: 2, default: 0
      t.decimal :total_net, precision: 12, scale: 2, default: 0
      t.decimal :total_gross, precision: 12, scale: 2, default: 0 

      t.timestamps
    end

    add_index :calculation_rows, :position
  end
end
