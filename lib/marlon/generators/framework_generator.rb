# lib/marlon/generators/framework_generator.rb — new-framework generator
require_relative "base_generator"

module Marlon
  module Generators
    class FrameworkGenerator < BaseGenerator
      def initialize(name)
        @name = name
        @lib_name = name.downcase
        @module_name = name.split(/_|-/).map(&:capitalize).join
      end

      def generate
        create_gem_structure
        puts "Framework #{@module_name} scaffold created. Run bundle install inside the new folder."
      end

      def create_gem_structure
        base = @lib_name
        FileUtils.mkdir_p("#{base}/lib/#{@lib_name}")
        write_file("#{base}/lib/#{@lib_name}.rb", "require \"#{@lib_name}/version\"\n\nmodule #{@module_name}\nend\n")
        write_file("#{base}/lib/#{@lib_name}/version.rb", "module #{@module_name}\n  VERSION = '0.1.0'\nend\n")
        write_file("#{base}/Gemfile", "source 'https://rubygems.org'\n\ngemspec\n")
        write_file("#{base}/#{@lib_name}.gemspec", <<~GEMSPEC)
          Gem::Specification.new do |spec|
            spec.name          = "#{@lib_name}"
            spec.version       = "0.1.0"
            spec.summary       = "MARLON-based component #{@module_name}"
            spec.files         = Dir["lib/**/*", "README.md"]
            spec.require_paths = ["lib"]
            spec.add_development_dependency "rake"
          end
        GEMSPEC
      end
    end
  end
end
