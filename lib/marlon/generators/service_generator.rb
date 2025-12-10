# lib/marlon/generators/service_generator.rb
require_relative "base_generator"

module Marlon
  module Generators
    class ServiceGenerator < BaseGenerator
      def initialize(name)
        raise "Service name required" unless name
        @name = name
        @class_name = name.split(/_|-/).map(&:capitalize).join
        @file_name = underscore(name)
      end

      def generate
        content = render("service.rb.tt", class_name: @class_name)
        write_file(File.join(Dir.pwd, "app", "marlon", "services", "#{@file_name}.rb"), content)
      end

      private

      def underscore(name)
        name.gsub(/([A-Z])/, '_\1').sub(/^_/, '').downcase
      end
    end
  end
end
