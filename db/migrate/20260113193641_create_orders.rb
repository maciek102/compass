class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.references :offer, foreign_key: true
      t.references :user, foreign_key: true
      t.string :number
      t.string :external_number
      t.string :status
      t.boolean :disabled
      t.integer :id_by_org

      t.timestamps
    end

    add_index :orders, [:organization_id, :id_by_org], unique: true, name: 'index_orders_on_org_and_id_by_org'
  end
end
