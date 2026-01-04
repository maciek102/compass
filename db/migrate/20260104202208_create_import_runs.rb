class CreateImportRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :import_runs do |t|
      t.references :organization, null: false
      t.references :user, null: false
      t.string :resource, null: false
      t.string :file_name
      t.integer :status, default: 0
      t.integer :total_rows
      t.integer :processed_rows
      t.integer :created_count
      t.integer :updated_count
      t.integer :error_count
      t.jsonb :import_errors
      t.jsonb :meta
      t.integer :id_by_org, null: false
      
      t.timestamps
    end

    add_index :import_runs, [:organization_id, :id_by_org], unique: true, name: "index_import_runs_on_org_and_id_by_org"
  end
end
