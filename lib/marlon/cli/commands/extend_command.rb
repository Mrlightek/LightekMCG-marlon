# lib/marlon/cli/commands/extend_command.rb
module Marlon::CLI::Commands
      class ExtendCommand
        def self.register(cli)
          cli.desc "extend MODULE_NAME", "Scaffold a Marlon module"
          cli.define_method(:extend) do |module_name|
            base_dir = "marlon/modules/#{module_name.downcase}"
            FileUtils.mkdir_p("#{base_dir}/reactions")
            %w[cloud_gate.rb cloud_service.rb cloud_registry.rb cloud_scheduler.rb cloud_state_store.rb].each do |file|
              File.write("#{base_dir}/#{file}", "// TODO: implement #{file}")
            end
            puts "✅ Marlon module #{module_name} scaffolded at #{base_dir}"
          end
        end
      end
    end
