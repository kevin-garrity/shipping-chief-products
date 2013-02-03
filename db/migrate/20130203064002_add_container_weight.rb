class AddContainerWeight < ActiveRecord::Migration
  def change
    add_column :preference, :container_weight, :decimal
  end
end
