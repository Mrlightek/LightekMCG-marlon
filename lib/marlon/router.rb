# lib/marlon/router.rb
module Marlon
  class Router
    @routes = {}

    class << self
      def map(key, handler = nil, &block)
        @routes[key.to_s] = block_given? ? block : handler
      end

      def routes
        @routes
      end

      def route(payload)
        raise ArgumentError, "payload must be a Hash" unless payload.is_a?(Hash)
        # allow nested shapes: {service: 'UserCreator', action:'create', payload: {...}}
        key = payload[:service] || payload[:action] || payload[:action_key] || payload[:type] || payload[:action] || payload[:route] || payload[:action_name]
        key = key.to_s
        handler = @routes[key]

        if handler.nil?
          # fallback to Marlon::Services::<Key>Service
          class_name = "#{key.split(/_|::/).map(&:capitalize).join}Service"
          if defined?(Marlon::Services) && Marlon::Services.const_defined?(class_name)
            svc = Marlon::Services.const_get(class_name).new
            return svc.call(payload)
          end
          raise NameError, "No route or service for action/service: #{key.inspect}"
        end

        if handler.is_a?(Proc)
          handler.call(payload)
        elsif handler.is_a?(Class) || handler.is_a?(Module)
          inst = handler.is_a?(Class) ? handler.new : handler
          if inst.respond_to?(:call)
            inst.call(payload)
          elsif inst.respond_to?(:perform)
            inst.perform(payload)
          else
            raise "#{handler} must implement call(payload) or perform(payload)"
          end
        else
          raise "Unsupported handler type for #{key}: #{handler.class}"
        end
      end
    end
  end
end
