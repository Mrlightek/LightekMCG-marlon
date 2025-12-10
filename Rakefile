# Rakefile
require "rake"

task :default do
  puts "Available tasks: gem:build, gem:install"
end

namespace :gem do
  desc "Build gem"
  task :build do
    sh "gem build marlon.gemspec"
  end

  desc "Build and install gem locally"
  task :install => :build do
    gem_file = Dir["marlon-*.gem"].sort.last
    sh "gem install #{gem_file} --local"
  end
end
