class CreateNames < ActiveRecord::Migration
  def change
    create_table :names do |t|
      t.string :name, null: false
      t.string :language_iso, :limit => 3, null: false  
      
      t.integer :nameable_id, null: false
      t.string  :nameable_type, null: false
      # trenger ikke denne likevel, siden taxon har bare en assosiasjon til Name
      #t.string  :nameable_subtype

      t.timestamps null: false
    end
#    add_index :names, [:nameable_id, :nameable_type, :nameable_subtype, :language_iso], :unique => true, :name => 'unique_names_per_type_languages'
    add_index :names, [:nameable_id, :nameable_type, :language_iso], :unique => true, :name => 'unique_names_per_type_languages'
  end
end
