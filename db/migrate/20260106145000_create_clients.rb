class CreateClients < ActiveRecord::Migration[8.1]
  def change
    create_table :clients do |t|
      t.references :organization, null: false, foreign_key: true
      t.integer :id_by_org, null: false

      t.string :name, null: false
      t.string :email, null: false

      t.string :tax_id
      t.string :registration_number

      t.string :phone
      t.string :address

      t.boolean :disabled, default: false

      t.timestamps
    end

    add_index :clients, [:organization_id, :id_by_org], unique: true, name: 'index_clients_on_org_and_id_by_org'
    add_index :clients, [:organization_id, :email], unique: true, where: "(email IS NOT NULL)", name: 'index_clients_on_organization_id_and_email'
    add_index :clients, [:organization_id, :tax_id], unique: true, where: "(tax_id IS NOT NULL AND tax_id != '')", name: 'index_clients_on_organization_id_and_tax_id'
  end
end
