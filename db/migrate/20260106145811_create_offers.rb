class CreateOffers < ActiveRecord::Migration[8.1]
  def change
    create_table :offers do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :client, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :id_by_org, null: false
      t.string :number
      t.string :external_number
      t.integer :status, default: 0
      t.boolean :disabled

      t.timestamps
    end

    add_index :offers, [:organization_id, :id_by_org], unique: true, name: 'index_offers_on_org_and_id_by_org'
  end
end
