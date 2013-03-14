class RatesController < ApplicationController

  def shipping_rates
    puts("-------request is" + params.to_s)

    origin = params[:rate][:origin]
    destination = params[:rate][:destination]

    rate_array = Array.new
    rate_array << 
    {
       'service_name' => 'canadapost-overnight',
       'service_code' => 'ON',
       'total_price' =>  '12.95',
        'currency' => 'USD'
    }
    
    rate_array << 
    {
       'service_name' => 'canadapost-2dayground',
       'service_code' => '1D',
       'total_price' => '29.34',
        'currency' => 'USD'
    }
    packages = [
      Package.new(  100,                        # 100 grams
                    [93,10],                    # 93 cm long, 10 cm diameter
                    :cylinder => true),         # cylinders have different volume calculations

      Package.new(  (7.5 * 16),                 # 7.5 lbs, times 16 oz/lb.
                    [15, 10, 4.5],              # 15x10x4.5 inches
                    :units => :imperial)        # not grams, not centimetres
    ] 
    fedex = FedexRate.new()
    rates = fedex.get_rates(origin, destination, packages)
    puts("--rate from fedex is " + rates.to_s)
        
    puts("----- returning " + rate_array.to_json)
    render :json => {:rates => rate_array}
  end
end  