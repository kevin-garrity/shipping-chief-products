module Webify
  module ClientAccess
    class Railtie < Rails::Railtie
      initializer "webify_client_access.action_controller" do
        ActiveSupport.on_load(:action_controller) do
          include Webify::ClientAccess::Filter
        end
      end
    end
  end
end