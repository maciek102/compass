class AddSuperadminRoleToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :is_superadmin, :boolean, default: false, if_not_exists: true
    add_column :users, :superadmin_view, :boolean, default: false, if_not_exists: true
  end
  
  def down
    remove_column :users, :is_superadmin, if_exists: true
    remove_column :users, :superadmin_view, if_exists: true
  end
end
