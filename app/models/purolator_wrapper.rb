class PurolatorWrapper
  def initialize
  end
  
  
  def build_xml(origin, destination, items)
    
    total_weight_lb =0
    
    items.each do |item|
      weight_grams=item[:grams].to_i
      weight_kg = weight_grams / 1000
      weight_lb = 2.20462 * weight_kg
      quan = item[:quantity].to_i
      
      total_weight_lb += quan * weight_lb
    end
    
    template = '<?xml version="1.0" encoding="utf-8"?>
    <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
      <soap:Header>
        <RequestContext xmlns="http://purolator.com/pws/datatypes/v1">
          <Version>1.3</Version>
          <Language>en</Language>
          <GroupID/>
          <RequestReference>RequestReference</RequestReference>
        </RequestContext>
      </soap:Header>
      <soap:Body>
        <GetQuickEstimateRequest xmlns="http://purolator.com/pws/datatypes/v1">
          <BillingAccountNumber>9999999999</BillingAccountNumber>
          <SenderPostalCode>SenderPostalCodeValue</SenderPostalCode>
          <ReceiverAddress>
            <City>Burnaby</City>
            <Province>BC</Province>
            <Country>CA</Country>
            <PostalCode>ReceiverPostalCodeValue</PostalCode>
          </ReceiverAddress>
          <PackageType>CustomerPackaging</PackageType>
          <TotalWeight>
            <Value>total_weight_lb</Value>
            <WeightUnit>lb</WeightUnit>
          </TotalWeight>
        </GetQuickEstimateRequest>
      </soap:Body>
    </soap:Envelope>'

    template = template.sub("total_weight_lb", total_weight_lb.ceil.to_s)
    template = template.sub("SenderPostalCodeValue", origin.postal_code)
    template = template.sub("ReceiverPostalCodeValue", destination.postal_code)
    
    return template
  end
  
  #items should contain the proper size of all the items
  #origin and destination are activeshipping location object
  def get_rates(origin, destination, items)
    client = Savon.client(
    wsdl: "https://webservices.purolator.com/EWS/V1/Estimating/WSDLs/EstimatingService.wsdl", 
    namespace: "http://purolator.com/pws/service/v1", 
    endpoint:"https://devwebservices.purolator.com/EWS/V1/Estimating/EstimatingService.asmx",
    basic_auth:["f9ce98cd171b4472b5074e30146e8fd2","61pbAQHg"],
    env_namespace: "soap",
    soap_header:   {  
    "RequestContext"=>
      {
        Version: "1.3", 
        Language: "en", 
        GroupID: "xxx", 
        RequestReference: "Rating Example"
        }
    }
    )
    
    message = 
    {
      BillingAccountNumber: "9999999999",
      SenderPostalCode: "L4W5M8",
      ReceiverAddress: 
      {
        City: "Burnaby",
        Province: "BC",
        Country: "CA",
        PostalCode: "V3N2G9"
        
      },
      PackageType: "CustomerPackaging",
      TotalWeight: 
      {
        Value: "10",
        WeightUnit: "lb"        
      }            
    }
    
    xml_message = build_xml(origin, destination, items)
    
    response = client.call(
      :get_quick_estimate, 
      message: message,
      soap_action: "http://purolator.com/pws/service/v1/GetQuickEstimate",
      xml: xml_message
    ) 
    res = response.hash
        
    rates = res[:envelope][:body][:get_quick_estimate_response][:shipment_estimates][:shipment_estimate]
        
    return_array = rates.collect{ |service| {"service_name" => service[:service_id], 'service_code'=> service[:service_id], 'total_price' => service[:total_price], 'currency' => "CAD"} }
    
    puts("return array is #{pp return_array}")
  end
end
