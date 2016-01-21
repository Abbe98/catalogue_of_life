class CreateTaxa < ActiveRecord::Migration
  def change
    create_table :taxa do |t|
      t.string :taxon_scientific_name, null: false
      t.string :slug
      t.integer :col_taxon_id, null: false
      t.references :parent, index: true
      t.references :taxonomy, index: true, null: false
      t.string :type, null: false, default: "Taxon"
      t.timestamps null: false
    end
    create_table :ranks do |t|
      t.string :rank, null: false
      t.string :language_iso, null: false
      t.timestamps null: false
    end    
    create_table :ranks_taxa, id: false do |t|
      t.belongs_to :taxon, index: true
      t.belongs_to :rank, index: true
    end
    # mulig at denne ikke virker for andre databaser enn MySQL, siden slug kan være null
    add_index :taxa, [:slug], :unique => true
  end
end
