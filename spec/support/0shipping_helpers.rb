require 'dalli'

begin
  Dalli::Client.new.get('stuff')
rescue
  system "memcached &"
end

module ShippingHelpers
  def fixtures_dir
    File.join(File.dirname(__FILE__), '..', 'fixtures')
  end
end


