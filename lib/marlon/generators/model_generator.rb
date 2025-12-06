# lib/marlon/generators/model_generator.rb
require_relative "base_generator"

module Marlon
  module Generators
    class ModelGenerator < BaseGenerator
      def initialize(name, fields = [])
        @name = name
        @fields = fields
        @class_name = classify(name)
        @file_name = underscore(name)
      end

      def generate
        attributes = @fields.map do |f|
          name, type = f.split(":")
          "  attribute :#{name}, :#{(type || 'string')}"
        end.join("\n")
        content = render("model.rb.tt", class_name: @class_name, attributes: attributes)
        path = "lib/marlon/models/#{@file_name}.rb"
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
