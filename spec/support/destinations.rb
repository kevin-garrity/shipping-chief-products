module Destinations
  def self.US
    {country: 'US'}
  end
  def self.zone1
    Destinations.US.merge(province: 'CA')
  end
  def self.zone2
    Destinations.US.merge(province: 'UT')
  end
  def self.zone3
    Destinations.US.merge(province: 'CO')
  end
  def self.zone4
    Destinations.US.merge(province: 'MO')
  end
  def self.zone5
    Destinations.US.merge(province: 'OH')
  end
end