AppConfig = ConfigSpartan.create do
  ['app_config', "app_config_#{Rails.env}", 'app_config_local'].each do |f|
    f << ".yaml"
    f = Rails.root.join('config', f)
    file f if File.exist?(f)
  end
end

DOMAIN_NAMES = {"staging" => "test.biguglyurl.com", "development" => "localhost:3000", "production" =>  "shipping.webifytechnology.com", "test" => "localhost:3000"}