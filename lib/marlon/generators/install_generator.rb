#lib/marlon/generators/install_generator.rb

#(marlon g install)

#This writes config files into your Rails / Lightek Server.

module Marlon
  module Generators
    class InstallGenerator
      def generate
        create_initializer
        create_config
      end

      def create_initializer
        path = "config/initializers/marlon.rb"
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, <<~RUBY)
          # MARLON Framework Initialization
          Marlon.boot!
        RUBY
        puts "Created #{path}"
      end

      def create_config
        path = "config/marlon.yml"
        File.write(path, <<~YAML)
          # Default MARLON configuration
          logging: true
          debug: false
        YAML
        puts "Created #{path}"
      end
    end
  end
end
