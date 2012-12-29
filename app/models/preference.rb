class Preference
  NAMESPACE = "WorldShipCalculator"

  # include ActiveModel::Model
  extend  ActiveModel::Naming
  extend  ActiveModel::Translation
  include ActiveModel::Validations
  include ActiveModel::Conversion

  attr_accessor :bob, :mary, :_metafields


  def attributes
    {
      bob: nil,
      mary: nil
    }
  end

  def initialize(params={})
    params.each do |attr, value|
      self.public_send("#{attr}=", value)
    end if params
  end

  def persisted?
    @_persisted
  end

  def self.find
    pref = Preference.new
    pref._metafields = ShopifyAPI::Metafield.find(:all, 
      params: {namespace: NAMESPACE, owner_resource: "shop"})
    pref._metafields.each { |mf| pref.public_send("#{mf.key}=", mf.value) }
    pref
  end


  def save
    attributes.each do |name, d|
      value = self.public_send(name)

      metafield = _metafields.find{|mf| mf.key == name }
      metafield ||= ShopifyAPI::Metafield.new({
        namespace: NAMESPACE,
        owner_resource: "shop",
        key: name,
        value_type: value.is_a?(Integer) ? "integer" : "string"
      })
      metafield.value = value
      metafield.save
    end
    @_persisted = true
  end


end