# lib/marlon/docs/parser.rb
require "yard"

module Marlon
  module Docs
    class Parser
      def self.parse(paths)
        YARD::Registry.clear
        YARD::Parser::SourceParser.parse(paths)

        objects = YARD::Registry.all(:method)

        objects.map do |obj|
          next unless obj.has_tag?("marlon")

          {
            type: obj.tag("marlon").text,      # "service" or "command"
            name: obj.name.to_s,
            path: obj.file,
            description: obj.docstring.to_s.strip,
            params: build_params(obj),
            returns: build_return(obj),
            examples: obj.tags("example").map(&:text)
          }
        end.compact
      end

      def self.build_params(obj)
        obj.tags("param").map do |param|
          {
            name: param.name,
            types: param.types,
            text: param.text
          }
        end
      end

      def self.build_return(obj)
        tag = obj.tag("return")
        return nil unless tag
        { types: tag.types, text: tag.text }
      end
    end
  end
end
