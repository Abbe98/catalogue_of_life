class CreateTaxonomies < ActiveRecord::Migration
  def change
    create_table :taxonomies do |t|
      t.timestamps null: false
    end
  end
end
