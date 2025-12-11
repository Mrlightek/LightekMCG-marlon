# lib/marlon/cli/commands/docs_command.rb
module Marlon
  module CLI
    module Commands
      class DocsCommand
        def self.register(cli)
          cli.desc "docs build", "Generate docs (Markdown, JSON, HTML site + Postman collection)"
          cli.define_method("docs") do |action = nil|
            if action == "build" || action.nil?
              Marlon::Generators::DocsGenerator.new.generate
            else
              puts "Unknown docs action: \#{action}"
            end
          end
        end
      end
    end
  end
end
