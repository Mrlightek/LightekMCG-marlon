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
        attribute_definitions = @fields.map do |f|
          name, type = f.split(":")
          type ||= "string"

          case type
          when "references", "reference"
            "  reference :#{name}"
          when "attachment"
            "  attachment :#{name}"
          when "attachments"
            "  attachments :#{name}"
          else
            "  attribute :#{name}, type: :#{type}, default: nil"
          end
        end

        content = render("model.rb.tt", class_name: @class_name, attributes: attribute_definitions.join("\n"))
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
