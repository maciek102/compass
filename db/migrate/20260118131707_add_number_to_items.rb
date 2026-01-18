class AddNumberToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :number, :string
    add_index :items, [:organization_id, :number], unique: true
  end
end
