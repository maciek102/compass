class CreateOrganizations < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations do |t|
      t.string :name
      t.text :description
      t.boolean :disabled, default: false
      t.boolean :launched, default: false

      t.timestamps
    end

    add_index :organizations, :name, unique: true
  end
end
