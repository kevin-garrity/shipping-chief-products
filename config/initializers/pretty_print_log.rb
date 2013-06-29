if Rails.env.development? 
  require 'pp'
  module Kernel
    def ppl(obj)
      pps = StringIO.new
      PP.pp(obj, pps)
      Rails.logger.add(ActiveSupport::BufferedLogger::DEBUG) {
        "\e[33m" +
        pps.string + 
       "\e[0m"
      }
    end
    module_function :ppl
  end
elsif Rails.env.test?
  module Kernel
    def ppl(obj); pp obj; end
  end
else
  module Kernel
    def ppl(obj);end
  end
end