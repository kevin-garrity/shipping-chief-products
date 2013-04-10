module Webify
  module ClientAccess
    module Filter
      extend ActiveSupport::Concern

      included do
        helper_method :allow_client_access?, :default_client_config, :default_client?, :client_config
      end

      module ClassMethods
        def client_access(key)
          before_filter do |controller| 
            unless controller.allow_client_access?(key)
              access_restricted
            end
          end
        end
      end

      def allow_client_access?(key) 
        #WARN: don't try to use except as a key in AppConfig (or any other method that Hash has)
        access = client_config.access
        return false unless access
        return true if access.only && access.only.include?(key)
        return false if access.all_except && access.all_except.include?(key)
        return true if access[key]
        return false if  access.only && !access.only.include?(key)

        unless default_client?
          access = default_client_config.access
          return false unless access
          return true if access.only && access.only.include?(key)
          return false if access.all_except && access.all_except.include?(key)
          return true if access[key]
        end

        return false
      end

      def default_client_config
        AppConfig.clients[:default]
      end

      def default_client?
        client_config ==  default_client_config
      end

      def client_config
        if shop_session
          if AppConfig.clients[shop_session.url]
            default_client_config.deep_merge!(AppConfig.clients[shop_session.url])
          elsif default_client_config
            default_client_config
          end
        elsif AppConfig
          {}
        end
      end

      def access_restricted
        redirect_to root_path
      end
    end
  end
end