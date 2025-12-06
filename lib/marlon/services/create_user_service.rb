# lib/marlon/services/create_user_service.rb
module Marlon
  module Services
    class CreateUserService < Marlon::Service
      def call(payload)
        data = payload[:data]
        # Framework logic here
        puts "Creating user with #{data.inspect}"
      end
    end
  end
end
