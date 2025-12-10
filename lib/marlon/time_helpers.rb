# lib/marlon/time_helpers.rb
module Marlon
  module TimeHelpers
    def self.seconds(n); n; end
    def self.minutes(n); n * 60; end
    def self.hours(n);   n * 3600; end
  end
end
