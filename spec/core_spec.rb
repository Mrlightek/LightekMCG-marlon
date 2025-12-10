# spec/core_spec.rb
require "spec_helper"

RSpec.describe "Marlon core" do
  it "loads configuration" do
    expect(Marlon.config).to be_a(Hash)
  end

  it "has a router map" do
    expect(Marlon::Router.routes).to be_a(Hash)
  end
end
