#lib/marlon/generators/service_generator.rb
#(marlon g service UserCreator)

module Marlon
  module Generators
    class ServiceGenerator
      TEMPLATE = <<~RUBY
        module Marlon
          module Services
            class %{class_name} < Marlon::Service
              def call(payload)
                # TODO: Implement %{class_name}
                puts "[MARLON] Service %{class_name} received: \#{payload.inspect}"
              end
            end
          end
        end
      RUBY

      def initialize(name)
        @name = name
        @class_name = name.split("_").map(&:capitalize).join
      end

      def generate
        path = "lib/marlon/services/#{file_name}.rb"
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, TEMPLATE % { class_name: @class_name })
        puts "Created #{path}"
      end

      private

      def file_name
        @name.gsub(/([a-z])([A-Z])/, '\1_\2').downcase
      end
    end
  end
end
