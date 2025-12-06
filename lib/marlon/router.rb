# lib/marlon/router.rb
module Marlon
  class Router
    class << self
      def route(payload)
        raise ArgumentError, "payload must be a Hash" unless payload.is_a?(Hash)

        action = payload[:action]&.to_sym
        raise "Missing :action key in payload" unless action

        service_class = resolve_service(action)
        service = service_class.new

        if service.respond_to?(:call)
          service.call(payload)
        else
          raise "#{service_class} must implement #call"
        end
      end

      private

      def resolve_service(action)
        service_name = "#{action.to_s.camelize}Service"
        Marlon::Services.const_get(service_name)
      rescue NameError
        raise "No MARLON service found for action: #{action}"
      end
    end
  end
end
