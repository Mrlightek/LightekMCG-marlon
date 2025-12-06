# lib/marlon/generators/router_generator.rb
require_relative "base_generator"

module Marlon
  module Generators
    class RouterGenerator < BaseGenerator
      def generate
        content = render("router.rb.tt", {})
        path = "lib/marlon/router.rb"
        write_file(path, content)
      end
    end
  end
end
