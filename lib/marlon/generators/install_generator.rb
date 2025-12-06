#lib/marlon/generators/install_generator.rb

#(marlon g install)

#This writes config files into your Rails / Lightek Server.

require_relative "base_generator"

module Marlon
  module Generators
    class InstallGenerator < BaseGenerator
      def generate
        create_initializer
        create_config
        create_middleware
        ensure_autoload_paths
      end

      def create_initializer
        path = "config/initializers/marlon.rb"
        return puts("#{path} already exists") if File.exist?(path)

        content = <<~RUBY
          # MARLON initializer
          Marlon.boot!
          # Load marlon config (config/marlon.yml)
          if File.exist?(Rails.root.join("config", "marlon.yml"))
            cfg = YAML.load_file(Rails.root.join("config", "marlon.yml"))
            Marlon::Framework.initialize!(cfg)
          end
        RUBY

        write_file(path, content)
      end

      def create_config
        path = "config/marlon.yml"
        if File.exist?(path)
          puts "#{path} already exists"
        else
          write_file(path, <<~YAML)
            # Marlon configuration
            logging: true
            debug: false
            gatekeeper:
              auth_token: "change_me"
          YAML
        end
      end

      def create_middleware
        path = "app/middleware/marlon_payload_handler.rb"
        return puts("#{path} already exists") if File.exist?(path)

        content = <<~RUBY
          # app/middleware/marlon_payload_handler.rb
          class MarlonPayloadHandler
            def initialize(app)
              @app = app
            end

            def call(env)
              # You can inspect env and route internal marlon payloads if needed
              @app.call(env)
            end
          end
        RUBY

        write_file(path, content)

        # Try to insert into application.rb
        application_rb = "config/application.rb"
        if File.exist?(application_rb)
          content = File.read(application_rb)
          marker = "class Application < Rails::Application"
          unless content.include?("MarlonPayloadHandler")
            new_content = content.sub(marker, "#{marker}\n    config.middleware.use \"MarlonPayloadHandler\"")
            if new_content == content
              puts "Could not automatically insert middleware in #{application_rb}. Add:\n\n    config.middleware.use \"MarlonPayloadHandler\"\n\nManually."
            else
              write_file(application_rb, new_content)
              puts "Inserted MarlonPayloadHandler middleware into #{application_rb}"
            end
          else
            puts "Middleware already configured in #{application_rb}"
          end
        else
          puts "No config/application.rb found — please add the middleware registration manually if desired."
        end
      end

      def ensure_autoload_paths
        # Try to add lib/marlon to autoload paths in config/application.rb
        application_rb = "config/application.rb"
        if File.exist?(application_rb)
          content = File.read(application_rb)
          unless content.include?('config.autoload_paths << Rails.root.join("lib")')
            inject = "\n    # Ensure lib is autoloaded for MARLON\n    config.autoload_paths << Rails.root.join('lib')\n"
            new_content = content.sub(/class Application < Rails::Application/, "class Application < Rails::Application\n#{inject}")
            if new_content == content
              puts "Could not automatically adjust autoload_paths. Add: config.autoload_paths << Rails.root.join('lib') to config/application.rb"
            else
              write_file(application_rb, new_content)
              puts "Updated config/application.rb to autoload lib/"
            end
          else
            puts "autoload_paths already configured"
          end
        end
      end
    end
  end
end
