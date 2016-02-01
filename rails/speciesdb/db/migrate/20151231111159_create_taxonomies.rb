class CreateTaxonomies < ActiveRecord::Migration
  def change
    create_table :taxonomies do |t|
      t.string :slug, null: false
      t.string :product_name, null: false
      t.timestamps null: false
    end
  end
end
