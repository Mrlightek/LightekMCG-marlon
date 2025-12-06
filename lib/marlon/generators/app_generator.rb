#lib/marlon/generators/app_generator.rb

#(marlon new my_framework_extension)

#Creates a new MARLON-based gem or service.

module Marlon
  module Generators
    class AppGenerator
      def initialize(app_name)
        @app_name = app_name
      end

      def generate
        system("bundle gem #{@app_name} --test=minitest --mit")
        puts "Created new MARLON component #{@app_name}"
      end
    end
  end
end
