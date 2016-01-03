class CreateTaxons < ActiveRecord::Migration
  def change
    create_table :taxa do |t|
      t.string :scientific_name, null: false
      t.integer :col_taxon_id, null: false
      t.references :parent, index: true
      t.string :type, null: false, default: "Taxon"

      t.timestamps null: false
    end
  end
end
