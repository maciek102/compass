class CreateOrganizationProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :organization_profiles do |t|
      t.references :organization, null: false, foreign_key: true, index: { unique: true }
      t.string :company_name
      t.string :tax_id
      t.string :registration_number
      t.string :address_street
      t.string :address_building
      t.string :address_apartment
      t.string :address_city
      t.string :address_postcode
      t.string :address_country
      t.string :contact_email
      t.string :contact_phone
      t.string :inpost_organization_id
      t.text :inpost_api_key

      t.timestamps
    end
  end
end
