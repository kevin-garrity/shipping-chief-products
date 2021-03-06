class EgoApiWrapper
  include ActiveMerchant::Shipping
  
  require "net/http"
  require "uri"
  
  def initialize
  end
  
  #items should contain the proper size of all the items
  #origin and destination are activeshipping location object
  def get_rates(origin, destination, items, booking_type)
    base_url = "http://www.e-go.com.au/calculatorAPI"
    puts("origin EgoApiWrapper:get_rates is #{origin.class.to_s}") if Rails.env.test?
    pickup = origin.postal_code
    delivery=destination.postal_code
        
    rates = Array.new
    items.each do |item|
      width=item[:width].to_f.round(0).to_i
      height=item[:height].to_f.round(0).to_i
      length=item[:length].to_f.round(0).to_i
      weight_grams=item[:grams].to_i
      weight_kg = (weight_grams.to_f / 1000).ceil
      quan = item[:quantity].to_i
      
      #only get rate for one box
      query = "#{base_url}?pickup=#{pickup}&delivery=#{delivery}&type=Carton&width=#{width}&height=#{height}&depth=#{length}&weight=#{weight_kg.to_s}&items=1"
      
      
      
      unless booking_type.blank?
        query+= "&bookingtype=#{booking_type}"
      end
      puts("Qeury is #{query}")
      uri = URI.parse(query)
      
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)

      response = http.request(request)            
      
      ret = parse_response(response.body)
      
      ret[:price] = ret[:price].to_f * quan unless ret.nil?
      rates << ret unless ret.nil?
    end
    
    return_array = Array.new
    service_name ="E-Go"

    if (rates.empty?)
      return_array = [{"service_name" => "ERROR getting rates from e-go",  'service_code'=> "E-go", 'total_price' => 0.0, 'currency' => "AUD"}]
    else
      return_array = rates.collect{ |r| {"service_name" => "#{service_name} (#{r[:eta]})", 'service_code'=> r[:eta], 'total_price' => r[:price].to_f*100, 'currency' => "AUD"} }
    end
    puts("return_array is #{return_array.to_s}") if Rails.env.test?
    
    return return_array    
  end
  
  def parse_response(body)
    puts("body is #{body.to_s}")
    m = /(error=)(.+)/.match(body)
        
    return nil if m.nil?
    if (m[2] == "OK")
      m1 = /(eta=)(.+)/.match(body)
      m2 = /(price=)(.+)/.match(body)
      
      price = m2[2].to_f
      eta = m1[2].to_s
      h = {:price =>price, :eta => eta}
      return h
    end
    return nil
  end
  
end