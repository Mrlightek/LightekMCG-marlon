# lib/marlon/cli/commands/command_generator_command.rb
module Marlon
  module CLI
    module Commands
      class CommandGeneratorCommand
        def self.register(cli)
          cli.desc "g command NAME", "Generate a new command + generator pair"
          cli.define_method(:command) do |name|
            command_class_name = "#{name}Command"
            generator_class_name = "#{name}Generator"
            
            # Convert to snake_case for file names
            command_file = "lib/marlon/cli/commands/#{name.downcase}_command.rb"
            generator_file = "lib/marlon/generators/#{name.downcase}_generator.rb"

            # Create directories if they don't exist
            FileUtils.mkdir_p(File.dirname(command_file))
            FileUtils.mkdir_p(File.dirname(generator_file))

            # Command file boilerplate
            File.write(command_file, <<~RUBY)
              module Marlon
                module CLI
                  module Commands
                    class #{command_class_name}
                      def self.register(cli)
                        cli.desc "g #{name.downcase} ARGS", "Command #{name}"
                        cli.define_method("#{name.downcase}") do |*args|
                          #{generator_class_name}.new(*args).run
                        end
                      end
                    end
                  end
                end
              end
            RUBY

            # Generator file boilerplate
            File.write(generator_file, <<~RUBY)
              module Marlon
                module Generators
                  class #{generator_class_name}
                    def initialize(*args)
                      @args = args
                    end

                    def run
                      puts "✅ Running generator #{generator_class_name} with args: \#{@args.inspect}"
                      # TODO: implement your generator logic here
                    end
                  end
                end
              end
            RUBY

            puts "✅ Command created: #{command_file}"
            puts "✅ Generator created: #{generator_file}"
            puts "Now the CLI has a new command: 'marlon g #{name.downcase}'"
          end
        end
      end
    end
  end
end
