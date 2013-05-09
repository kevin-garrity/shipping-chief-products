class Webify::CarrierGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)
  argument :name, type: :string, required: true
  class_option :service, type: :boolean, default: true, description: "Include a rates service"  

  class_option :service_host, type: :string, default: 'webify-shipping.herokuapp.com', description: "Host for the rates service for production"  
 class_option :staging_service_host, type: :string, default: 'shipping-staging.herokuapp.com', description: "Host for the rates service for staging"  

  class_option :shop, type: :string, description: "Shop to grant access for production. Will be added to app_config_production -- set to 'none' to skip." 
  class_option :staging_shop, type: :string, description: "Shop to grant access for staging. Will be added to app_config_staging -- set to 'none' to skip.", required: false

  def create_files
    carrier_dir = "app/models/carriers/#{name.underscore}"
    empty_directory carrier_dir
    template "installer.rb.erb", "#{carrier_dir}/installer.rb"
    template "service.rb.erb", "#{carrier_dir}/service.rb"
  end

  def add_config
    shop = options.shop
    shop ||= "#{name.underscore}.myshopify.com"
    staging_shop = options.staging_shop
    staging_shop ||= shop
    app_config_path = 'config/app_config.yaml'
    app_config = YAML::load_file(app_config_path)
    app_config['carriers'] ||= {}
    if app_config['carriers'][name.underscore]
      say_status(:app_config, "carrier #{name.underscore} already exists", :blue)
    else
      app_config['carriers'][name.underscore] = {
        'public' => false,
        'description' => "Custom Rules -- #{name.titleize}",
        'service' => options.service?,
        'service_discovery' => false
      }
      say_status(:app_config, "add carrier #{name.underscore}", :green)
      File.open(app_config_path, 'w'){|f| f.write app_config.to_yaml}
    end

    unless options.shop == "none"
      prod_config_path = 'config/app_config_production.yaml'
      prod_config = YAML::load_file(prod_config_path)
      prod_config['clients'] ||= {}
      if prod_config['clients'][shop]
        say_status(:app_config, "production: client #{shop} already exists", :blue)
      else
        prod_config['clients'][shop] = {
          'access' => {'all_except' => []},
          'menus' => [],
          'carriers' => [name.underscore.to_sym],
          'service_host' => options.service_host
        }
        say_status(:app_config, "production: add client #{shop}", :green)
        File.open(prod_config_path, 'w'){|f| f.write prod_config.to_yaml}
      end
    end

    unless options.staging == "none"
      staging_config_path = 'config/app_config_staging.yaml'
      staging_config = YAML::load_file(staging_config_path)
      staging_config['clients'] ||= {}
      if staging_config['clients'][staging_shop]
        say_status(:app_config, "staging: client #{staging_shop} already exists", :blue)
      else
        staging_config['clients'][staging_shop] = {
          'access' => {'all_except' => []},
          'menus' => [],
          'carriers' => [name.underscore.to_sym],
          'service_host' => options.staging_service_host
        }
        say_status(:app_config, "staging: add client #{staging_shop}", :green)
        File.open(staging_config_path, 'w'){|f| f.write staging_config.to_yaml}
      end
    end
  end
end
