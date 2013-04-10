module Webify
  module Dev
    def self.get_ip
      con = Net::HTTP.new('checkip.dyndns.org', 80)
      r = con.get("/", {})
      ip = r.body.match(/\d+\.\d+\.\d+\.\d+/)
      ip[0]
    end

  end
end