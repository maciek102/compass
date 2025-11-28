class CreateProductCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :product_categories do |t|
      t.string :name
      t.string :slug
      t.references :product_category, null: false, foreign_key: true
      t.boolean :visible
      t.integer :position
      t.text :description
      t.boolean :disabled, default: false

      t.timestamps
    end
    add_index :product_categories, :slug
  end
end
