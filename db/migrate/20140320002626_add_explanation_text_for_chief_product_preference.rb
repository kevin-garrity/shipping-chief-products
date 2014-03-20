class AddExplanationTextForChiefProductPreference < ActiveRecord::Migration
  def up
    add_column :chief_products_preference, :aus_post_explanation, :string
    add_column :chief_products_preference, :ego_explanation, :string
    
  end

  def down
    remove_column :chief_products_preference, :aus_post_explanation
    remove_column :chief_products_preference, :ego_explanation
  end
end
