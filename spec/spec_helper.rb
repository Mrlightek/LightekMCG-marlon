# spec/spec_helper.rb
require "bundler/setup"
require "marlon"
RSpec.configure do |c|
  c.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
end
