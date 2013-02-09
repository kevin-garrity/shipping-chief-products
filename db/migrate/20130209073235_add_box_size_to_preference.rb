class AddBoxSizeToPreference < ActiveRecord::Migration
  def change
    add_column :preference, :default_box_size, :integer
  end
end
