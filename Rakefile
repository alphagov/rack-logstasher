require "bundler/gem_tasks"

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)

task :default => :spec

require "gem_publisher"
task :publish_gem do |t|
  gem = GemPublisher.publish_if_updated("rack-logstasher.gemspec", :rubygems)
  puts "Published #{gem}" if gem
end
