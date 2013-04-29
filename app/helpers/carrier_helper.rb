module CarrierHelper
  def carrier_name_for(name, config=nil)
    config ||= client_config
    name = client_config.carriers.detect { |key|
      name.to_s == key.to_s || ( AppConfig.carriers[key].legacy_name && (AppConfig.carriers[key].legacy_name == name.to_s ))
    }.to_s
  end

  def carrier_installer_class_for(name)
    return nil if name.blank?
    "carriers/#{carrier_name_for(name)}/installer".camelize.constantize
  end

  def carrier_service_class_for(name)
    return nil if name.blank?
    "carriers/#{carrier_name_for(name)}/service".camelize.constantize
  end

  def carrier_partial_for(name)
    "carriers/#{carrier_name_for(name).to_s}_form"
  end

  def client_carrier_choices
     client_config.carriers.map{|key| [AppConfig.carriers[key.to_s].description, key.to_s]}
  end

end
