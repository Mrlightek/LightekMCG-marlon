# lib/marlon/inflector.rb
module Marlon
  module Inflector
    def self.camelize(str)
      str.to_s.split('_').map(&:capitalize).join
    end

    def self.underscore(str)
      str.to_s
         .gsub(/::/, '/')
         .gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2')
         .gsub(/([a-z\d])([A-Z])/,'\1_\2')
         .tr("-", "_")
         .downcase
    end

    # naive pluralize (works for most simple nouns)
    def self.pluralize(str)
      s = underscore(str)
      return s if s.end_with?("s")
      if s.end_with?("y") && !%w[a e i o u].include?(s[-2])
        s[0..-2] + "ies"
      else
        s + "s"
      end
    end

    def self.constantize(str)
      Object.const_get(str)
    end
  end
end

