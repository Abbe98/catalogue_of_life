class CreateErrorLog < ActiveRecord::Migration
  def change
    create_table :error_log do |t|
      t.text :message
      t.timestamps null: false
    end
  end
end
