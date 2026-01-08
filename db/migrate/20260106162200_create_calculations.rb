class CreateCalculations < ActiveRecord::Migration[8.1]
  def change
    create_table :calculations do |t|
      t.references :organization, null: false, foreign_key: true
      t.integer :id_by_org, null: false

      t.bigint :calculable_id, null: false
      t.string :calculable_type, null: false
      t.references :user, foreign_key: true

      t.integer :version_number
      t.boolean :is_current

      t.decimal :total_net, precision: 12, scale: 2, default: 0
      t.decimal :total_vat, precision: 12, scale: 2, default: 0
      t.decimal :total_gross, precision: 12, scale: 2, default: 0
      t.decimal :total_discounts, precision: 12, scale: 2, default: 0
      t.decimal :total_margins, precision: 12, scale: 2, default: 0
      t.timestamps
    end

    add_index :calculations, [:organization_id, :id_by_org], unique: true, name: 'index_calculations_on_org_and_id_by_org'
    add_index :calculations, [:calculable_type, :calculable_id], name: 'index_calculations_on_calculable'
  end
end
