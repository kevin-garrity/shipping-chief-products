module ShopifyAPI
 class VariantWithProduct < Base
   self.prefix = "/admin/"
   self.element_name = "variant"
   self.collection_name = "variants"
 end
end