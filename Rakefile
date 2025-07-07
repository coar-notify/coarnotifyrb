# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

# Default RSpec task
RSpec::Core::RakeTask.new(:spec) do |t|
  t.exclude_pattern = "spec/integration/**/*_spec.rb"
end

# Integration tests (require external services)
RSpec::Core::RakeTask.new(:integration) do |t|
  t.pattern = "spec/integration/**/*_spec.rb"
  t.rspec_opts = "--tag integration"
end

# All tests including integration
RSpec::Core::RakeTask.new(:spec_all) do |t|
  # Run all specs
end

# RuboCop task
RuboCop::RakeTask.new

# Default task runs unit tests only
task default: [:spec, :rubocop]

# Task to run all tests
task all: [:spec_all, :rubocop]

desc "Run unit tests only"
task test: :spec

desc "Run all tests including integration tests"
task test_all: :spec_all

desc "Run integration tests only"
task test_integration: :integration

desc "Display test statistics"
task :test_stats do
  puts "Test Statistics:"
  puts "=" * 50
  
  # Count spec files
  unit_specs = Dir.glob("spec/**/*_spec.rb").reject { |f| f.include?("integration") }
  integration_specs = Dir.glob("spec/integration/**/*_spec.rb")
  
  puts "Unit test files: #{unit_specs.length}"
  puts "Integration test files: #{integration_specs.length}"
  puts "Total test files: #{unit_specs.length + integration_specs.length}"
  
  # Count fixture files
  fixtures = Dir.glob("spec/fixtures/**/*.rb")
  puts "Fixture files: #{fixtures.length}"
  
  # Count mock files
  mocks = Dir.glob("spec/mocks/**/*.rb")
  puts "Mock files: #{mocks.length}"
  
  puts "=" * 50
end

desc "Clean up generated files"
task :clean do
  FileUtils.rm_rf("coverage")
  FileUtils.rm_rf(".rspec_status")
  puts "Cleaned up generated files"
end
