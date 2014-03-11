module ShopifyAPI
 class VariantWithProduct < Base
   
   include Metafields
   
   self.prefix = "/admin/"
   self.element_name = "variant"
   self.collection_name = "variants"
 end
end