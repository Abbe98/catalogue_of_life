class CreateSources < ActiveRecord::Migration
  def change
    create_table :sources do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :version

      t.timestamps null: false
    end
    # mulig at denne ikke virker for andre databaser enn MySQL, siden slug kan være null
    #add_index :sources, [:slug], :unique => true
  end
end
