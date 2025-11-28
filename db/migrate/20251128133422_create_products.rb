class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name
      t.text :description
      t.references :product_category, null: false, foreign_key: true
      t.string :slug
      t.boolean :disabled, default: false
      t.text :notes
      t.string :sku
      t.integer :status

      t.timestamps
    end
    add_index :products, :slug
    add_index :products, :name
  end
end
