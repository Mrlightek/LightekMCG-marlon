# lib/marlon/generators/base_generator.rb
require "fileutils"
require "erb"

module Marlon
  module Generators
    class BaseGenerator
      TEMPLATE_DIR_GEM = File.expand_path("../../templates", __dir__)
      USER_TEMPLATE_DIRS = [
        File.join(Dir.pwd, ".marlon", "templates"),
        File.join(Dir.home || "~", ".marlon", "templates")
      ].freeze

      def read_template(name)
        # Check user templates first
        USER_TEMPLATE_DIRS.each do |d|
          path = File.join(d, name)
          return File.read(path) if File.exist?(path)
        end

        # fallback: gem templates
        path = File.join(TEMPLATE_DIR_GEM, name)
        raise "Template not found: #{name}" unless File.exist?(path)
        File.read(path)
      end

      def render(template_name, locals = {})
        tpl = read_template(template_name)
        ERB.new(tpl, trim_mode: "-").result_with_hash(locals)
      end

      def write_file(path, content, mode: "w")
        dir = File.dirname(path)
        FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
        File.write(path, content, mode: mode)
        puts "Created #{path}"
      end

      def append_to_file(path, content)
        dir = File.dirname(path)
        FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
        File.open(path, "a") { |f| f.puts(content) }
        puts "Updated #{path}"
      end
    end
  end
end
