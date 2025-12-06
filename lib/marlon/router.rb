# lib/marlon/router.rb — default router (generators can create a more advanced one)
module Marlon
  class Router
    class << self
      def route(payload)
        unless payload.is_a?(Hash)
          raise ArgumentError, "Marlon.route expects a Hash payload"
        end

        action = payload[:action] || payload["action"]
        raise ArgumentError, "payload missing :action" unless action

        service_class = resolve_service_class(action)
        service = service_class.new
        service.call(payload)
      end

      private

      def resolve_service_class(action)
        # Normalize - accepts "create_user" or :create_user or "CreateUser"
        name = action.to_s
        # try camelize + Service suffix
        class_name = "#{camelize(name)}Service"
        const = safe_const_get("Marlon::Services::#{class_name}")
        return const if const

        raise NameError, "Service #{class_name} not found under Marlon::Services"
      end

      def camelize(str)
        str.to_s.split(/_|::/).map(&:capitalize).join
      end

      def safe_const_get(path)
        path.split("::").inject(Object) do |memo, part|
          return nil unless memo.const_defined?(part)
          memo.const_get(part)
        end
      rescue NameError
        nil
      end
    end
  end
end
