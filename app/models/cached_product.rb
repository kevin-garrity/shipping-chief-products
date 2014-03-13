class CachedProduct < ActiveRecord::Base
 attr_accessible :product_id, :sku, :height, :width, :length
 belongs_to :shop


end
