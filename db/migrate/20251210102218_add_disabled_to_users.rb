class AddDisabledToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :disabled, :boolean, default: false
  end
end
