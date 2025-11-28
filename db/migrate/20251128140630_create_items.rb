class CreateItems < ActiveRecord::Migration[8.1]
  def change
    create_table :items do |t|
      t.references :variant, null: false, foreign_key: true
      t.string :serial_number
      t.string :lot_number
      t.integer :status, default: 0
      t.string :location
      t.text :notes
      t.boolean :disabled, default: false

      t.timestamps
    end
    add_index :items, [:variant_id, :serial_number], unique: true
  end
end
