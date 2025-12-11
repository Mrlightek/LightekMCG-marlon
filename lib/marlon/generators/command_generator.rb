# lib/marlon/generators/command_generator.rb
require "fileutils"

module Marlon
  module Generators
    class CommandGenerator
      def initialize(name)
        @name          = name
        @snake         = underscore(name)
        @camel         = camelize(name)
      end

      def generate
        create_command
        create_generator
        create_service

        puts "🎉 Created command, generator, and service for #{@camel}"
        puts "➡️  Command:    lib/marlon/cli/commands/#{@snake}_command.rb"
        puts "➡️  Generator:  lib/marlon/generators/#{@snake}_generator.rb"
        puts "➡️  Service:    lib/marlon/services/#{@snake}.rb"
        puts ""
        puts "🔥 Your new service is callable through Gatekeeper immediately:"
        puts JSON.pretty_generate({
          service: @camel,
          action:  "default_action",
          payload: { example: true }
        })
      end

      private

      # ------------------------------------------
      # COMMAND FILE
      # ------------------------------------------
      def create_command
        path = "lib/marlon/cli/commands/#{@snake}_command.rb"
        FileUtils.mkdir_p(File.dirname(path))

        File.write(path, <<~RUBY)
          module Marlon
            module CLI
              class #{@camel}Command
                def self.run(*args)
                  puts "Running #{@camel} generator..."
                  Marlon::Generators::#{@camel}Generator.new(*args).generate
                end
              end
            end
          end
        RUBY
      end

      # ------------------------------------------
      # GENERATOR FILE
      # ------------------------------------------
      def create_generator
        path = "lib/marlon/generators/#{@snake}_generator.rb"
        FileUtils.mkdir_p(File.dirname(path))

        File.write(path, <<~RUBY)
          module Marlon
            module Generators
              class #{@camel}Generator
                def initialize(*args)
                  @args = args
                end

                def generate
                  puts "✅ #{@camel} generator invoked with: \#{@args.inspect}"
                  # Add your generator logic here
                end
              end
            end
          end
        RUBY
      end

      # ------------------------------------------
      # SERVICE FILE (Gatekeeper-compatible)
      # ------------------------------------------
      def create_service
        path = "lib/marlon/services/#{@snake}.rb"
        FileUtils.mkdir_p(File.dirname(path))

        File.write(path, <<~RUBY)
          module Marlon
            module Services
              class #{@camel}
                def initialize(params = {})
                  @params = params
                end

                # Default Gatekeeper action
                def default_action
                  {
                    message: "#{@camel}#default_action executed",
                    received: @params
                  }
                end
              end
            end
          end
        RUBY
      end

      # ------------------------------------------
      # Helpers
      # ------------------------------------------
      def underscore(str)
        str.gsub(/::/, '/')
           .gsub(/([A-Z]+)([A-Z][a-z])/,'\\1_\\2')
           .gsub(/([a-z\d])([A-Z])/,'\\1_\\2')
           .tr("-", "_")
           .downcase
      end

      def camelize(str)
        str.split('_').map(&:capitalize).join
      end
    end
  end
end
