class CachedProduct < ActiveRecord::Base
 attr_accessible :product_id, :sku, :height, :width, :length, :shop_id, :product_name
 belongs_to :shop


end
