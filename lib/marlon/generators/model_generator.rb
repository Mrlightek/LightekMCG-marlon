#lib/marlon/generators/model_generator.rb
#(marlon g model User name:string age:integer)

module Marlon
  module Generators
    class ModelGenerator
      TEMPLATE = <<~RUBY
        class %{class_name} < Marlon::Model
          %{attributes}
        end
      RUBY

      def initialize(name, fields)
        @name = name
        @fields = fields
      end

      def generate
        attribute_lines = build_attributes
        class_name = @name.split("_").map(&:capitalize).join
        path = "lib/marlon/models/#{file_name}.rb"

        FileUtils.mkdir_p(File.dirname(path))

        File.write(path, TEMPLATE % {
          class_name: class_name,
          attributes: attribute_lines
        })

        puts "Created #{path}"
      end

      private

      def build_attributes
        return "" if @fields.empty?

        @fields.map do |f|
          name, type = f.split(":")
          "attribute :#{name}, :#{type}"
        end.join("\n  ")
      end

      def file_name
        @name.downcase
      end
    end
  end
end
