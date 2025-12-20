# lib/marlon/generators/base_generator.rb
require "fileutils"
require "erb"

module Marlon
  module Generators
    class BaseGenerator
      TEMPLATE_DIR = File.expand_path("../templates", __dir__)
      USER_TEMPLATE_DIRS = [
        File.join(Dir.pwd, ".marlon", "templates"),
        File.join(Dir.home || "~", ".marlon", "templates")
      ].freeze

      def read_template(name)
        USER_TEMPLATE_DIRS.each do |d|
          path = File.join(d, name)
          return File.read(path) if File.exist?(path)
        end
        path = File.join(TEMPLATE_DIR, name)
        raise "Template not found: #{name} (looked in #{TEMPLATE_DIR})" unless File.exist?(path)
        File.read(path)
      end

      def render(template, locals = {})
        tpl = read_template(template)
        ERB.new(tpl, trim_mode: "-").result_with_hash(locals)
      end

      def write_file(path, content)
        dir = File.dirname(path)
        FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
        File.write(path, content)
        puts "Created #{path}"
      end

      def append_file(path, content)
        dir = File.dirname(path)
        FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
        File.open(path, "a") { |f| f.puts(content) }
        puts "Appended to #{path}"
      end
    end
  end
end
