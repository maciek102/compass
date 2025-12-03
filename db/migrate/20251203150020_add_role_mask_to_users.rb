class AddRoleMaskToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role_mask, :string
  end
end
