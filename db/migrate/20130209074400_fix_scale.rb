class FixScale < ActiveRecord::Migration
  def change
    change_column :preference, :width, :decimal, :precision => 10, :scale => 2    
    change_column :preference, :height, :decimal, :precision => 10, :scale => 2    
    change_column :preference, :length, :decimal, :precision => 10, :scale => 2    
    change_column :preference, :default_charge, :decimal, :precision => 10, :scale => 2    
    change_column :preference, :container_weight, :decimal, :precision => 10, :scale => 2    
  end
end
