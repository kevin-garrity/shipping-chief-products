class AddPreference < ActiveRecord::Migration
  def up
    create_table :preference do |t|
      t.string :shop_url
      t.string :origin_postal_code
      t.string :default_weight
      t.string :surchange_percentage
    end
  end

  def down
    drop_table :preference
  end
end
