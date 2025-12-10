# lib/marlon/generators/extend_generator.rb
require_relative "base_generator"
require "fileutils"

module Marlon
  module Generators
    class ExtendGenerator < BaseGenerator
      def initialize(name)
        raise "Module name required" unless name && !name.empty?
        @name = name.to_s.downcase
        @class_name = name.split(/_|-/).map(&:capitalize).join
      end

      def generate
        base = File.join(Dir.pwd, "modules", @name)
        template_files.each do |tpl, dest|
          content = render(tpl, module_name: @class_name, module_slug: @name)
          write_file(File.join(base, dest), content)
        end
        puts "Marlon module created at #{base}"
      end

      private

      def template_files
        {
          "extend/module.rb.tt" => "lib/#{@name}.rb",
          "extend/service.rb.tt" => "app/marlon/modules/#{@name}/services/#{@name}_service.rb",
          "extend/ops.rb.tt" => "app/marlon/modules/#{@name}/ops.rb",
          "extend/README.md.tt" => "README.md",
          "extend/marlon_routes.rb.tt" => "config/marlon_routes.rb"
        }
      end
    end
  end
end
