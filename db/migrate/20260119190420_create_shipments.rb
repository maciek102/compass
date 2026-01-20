class CreateShipments < ActiveRecord::Migration[8.1]
  def change
    create_table :shipments do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.string :provider
      t.integer :status
      t.string :tracking_number
      t.bigint :external_id
      t.integer :delivery_type
      t.string :locker_code
      t.string :recipient_name
      t.string :recipient_phone
      t.string :recipient_email
      t.string :address_country
      t.string :address_postcode
      t.string :address_city
      t.string :address_street
      t.string :address_house
      t.string :address_apartment
      t.text :error_message
      t.bigint :id_by_org
      t.boolean :disabled, default: false

      t.timestamps
    end
  end
end
