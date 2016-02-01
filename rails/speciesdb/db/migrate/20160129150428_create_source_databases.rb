class CreateSourceDatabases < ActiveRecord::Migration
  def change
    create_table :source_databases do |t|
      t.string :name
      t.string :authors_and_editors
      t.string :uri
      t.string :uri_scheme
      t.timestamps null: false
    end
  end
end
