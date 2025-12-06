# lib/marlon/generators/service_generator.rb
require_relative "base_generator"

module Marlon
  module Generators
    class ServiceGenerator < BaseGenerator
      def initialize(name)
        @name = name
        @class_name = classify(name)
        @file_name = underscore(name)
      end

      def generate
        content = render("service.rb.tt", class_name: @class_name, file_name: @file_name)
        path = "lib/marlon/services/#{@file_name}.rb"
        write_file(path, content)
      end

      private

      def classify(name)
        name.to_s.split(/_|-/).map(&:capitalize).join
      end

      def underscore(name)
        name.gsub(/([A-Z])/, '_\1').sub(/^_/, '').downcase
      end
    end
  end
end
