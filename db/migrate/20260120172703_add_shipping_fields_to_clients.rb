class AddShippingFieldsToClients < ActiveRecord::Migration[8.1]
  def change
    # Usuwamy stare pole address
    remove_column :clients, :address, :string
    
    # Dodajemy rozbite pola adresowe
    add_column :clients, :company_name, :string
    add_column :clients, :street, :string
    add_column :clients, :building_number, :string
    add_column :clients, :apartment_number, :string
    add_column :clients, :city, :string
    add_column :clients, :postcode, :string
    add_column :clients, :country_code, :string, default: 'PL'
  end
end
