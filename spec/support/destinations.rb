module Destinations

  def self.US
    us = {country: 'US'}
    us.define_singleton_method(:zone1){ self.merge(province: 'CA') }
    us.define_singleton_method(:zone2){ self.merge(province: 'UT') }
    us.define_singleton_method(:zone3){ self.merge(province: 'CO') }
    us.define_singleton_method(:zone4){ self.merge(province: 'MO') }
    us.define_singleton_method(:zone5){ self.merge(province: 'OH') }
    us
  end

  def self.CA; { country: 'CA' }; end
  def self.AU; { country: 'AU' }; end
  def self.PL; { country: 'PL' }; end
  def self.ZA; { country: 'ZA' }; end

end
