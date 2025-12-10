# lib/marlon/framework.rb
module Marlon
  class Framework
    def self.initialize!(opts = {})
      @opts ||= {}
      @opts.merge!(opts || {})
      Marlon.reload_config!
    end

    def self.setup_autoload(path)
      Marlon.loader.push_dir(File.expand_path(path, Dir.pwd)) if File.directory?(path)
    end
  end
end

