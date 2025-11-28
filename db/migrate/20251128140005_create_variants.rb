class CreateVariants < ActiveRecord::Migration[8.1]
  def change
    create_table :variants do |t|
      t.references :product, null: false, foreign_key: true
      t.string :name
      t.string :sku
      t.string :ean
      t.decimal :price, precision: 10, scale: 2
      t.integer :stock
      t.string :location
      t.decimal :weight
      t.jsonb :custom_attributes
      t.boolean :disabled, default: false
      t.text :note

      t.timestamps
    end
    add_index :variants, :sku
    add_index :variants, :name
  end
end
