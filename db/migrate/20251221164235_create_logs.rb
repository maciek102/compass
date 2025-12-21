class CreateLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :logs do |t|
      t.references :loggable, polymorphic: true, null: false, index: true
      t.references :user, foreign_key: true, index: true
      t.string :action
      t.text :message
      t.jsonb :details

      t.timestamps
    end

    add_index :logs, [:loggable_type, :loggable_id]
    add_index :logs, :action
    add_index :logs, :created_at
  end
end
