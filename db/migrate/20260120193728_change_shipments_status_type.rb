class ChangeShipmentsStatusType < ActiveRecord::Migration[8.1]
  def change
    change_column :shipments, :status, :string
  end
end
