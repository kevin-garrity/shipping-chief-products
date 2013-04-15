# Preferences Controller
* installs custom shipping service
  * register_custom_shipping_service
    * creates a ShopifyAPI::CarrierService
    * main param is callback url that points to rates_controller#shipping_rates
    *  refactor to a model? in any case need to make callback url configurable?
    *  WARN: deletes any existing ShopifyAPI::CarrierService
    *  currently the callback_url has shop_url query param, but in the shipping-fulfilment-app example they read this from request.headers['HTTP_X_SHOPIFY_SHOP_DOMAIN'], and they also verify the request against a sha THIS IS IMPORTANT FOR PRODUCTION UNLESS YOU WANT TO GET SUED

* view: uses get_supported_carriers to draw a select. Currently the list is hardcoded
* need to refactor to allow custom carriers for particular clients
* more evidence a carrier model is needed
* currently the whole setup only allows user to use one of our collection of carriers -- what if they want to select more than one? more evidence a carrier model is needed
* if the user is using more than one carrier we provide
* in PreferencesController#update there is an if (@preference.carrier == "AusPost"), more evidence need a model & polymorphism
* "Preference" really is like a carrier model but without inheritance and various if/else on its column "carrier"
* 


Webify::Carrier
name


Refactors:
* add client config & current client method like in metafield_editor
  * move get_supported_carriers 
* clean up preferences controller by creating two CarrierInstaller Objects and moving the polymorphic code there

CarrierInstaller.for(preference)

* add Carrier object, shipping_rates talks to this
* Carrier Object _should_ be an ActiveRecord eventually, and hang off shop. Preference should hang off Carrier (ie, composition, because the different carriers have attrs that are too different for STI)

* views:
  * app/views/carriers/auspost
  * app/views/carriers/foldabox

* canonicalize names. tell ziggy rationale -- there are these kinds of names:
  - under_score
  - camelCaseLower
  - CamelCaseUpper
  - Modularized::NameSpace
  - modularized/name_space
  - "Title Case"
  - multiplied by singular / plural
if you only use these in code, rails has methods to exchange between them

* Fedex_rate needs credentials factored out. Are fedex credentials per client?
