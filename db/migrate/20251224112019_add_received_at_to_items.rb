class AddReceivedAtToItems < ActiveRecord::Migration[8.1]
  def change
    add_column :items, :received_at, :datetime
  end
end
