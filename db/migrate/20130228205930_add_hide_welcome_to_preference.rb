class AddHideWelcomeToPreference < ActiveRecord::Migration
  def change
    add_column :preference, :hide_welcome_note, :bool
  end
end
