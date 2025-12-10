# lib/marlon/generators/proxy_generator.rb
require_relative "base_generator"

module Marlon
  module Generators
    class ProxyGenerator < BaseGenerator
      def generate
        content = render("proxy.yml.tt", {})
        write_file(File.join(Dir.pwd, "config", "proxy.yml"), content)
      end
    end
  end
end
