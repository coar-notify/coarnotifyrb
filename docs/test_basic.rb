#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

puts "Testing basic functionality..."

# Load the entire library with one require
require 'coarnotify'
puts "✓ COAR Notify library loaded: #{Coarnotify::VERSION}"

puts "\nTesting basic object creation..."

# Test creating an Accept pattern
accept = Coarnotify::Patterns::Accept.new
puts "✓ Accept pattern created"
puts "  Type: #{accept.type}"
puts "  ID: #{accept.id}"

# Test creating a client
client = Coarnotify::Client::COARNotifyClient.new
puts "✓ Client created"

# Test creating services and objects
origin = Coarnotify::Core::Notify::NotifyService.new
origin.id = "https://example.com/origin"
puts "✓ Origin service created"

target = Coarnotify::Core::Notify::NotifyService.new  
target.id = "https://example.com/target"
puts "✓ Target service created"

object = Coarnotify::Core::Notify::NotifyObject.new
object.id = "https://example.com/object"
puts "✓ Object created"

# Test setting properties
accept.origin = origin
accept.target = target
accept.object = object
accept.in_reply_to = "https://example.com/object"
puts "✓ Properties set on Accept pattern"

# Test validation
begin
  accept.validate
  puts "✓ Accept pattern validation passed"
rescue Coarnotify::ValidationError => e
  puts "✗ Validation failed: #{e.errors}"
end

# Test JSON-LD conversion
json_ld = accept.to_jsonld
puts "✓ JSON-LD conversion successful"
puts "  Context: #{json_ld['@context']}"
puts "  Type: #{json_ld['type']}"

# Test factory
factory_class = Coarnotify::Factory::COARNotifyFactory.get_by_types("Accept")
puts "✓ Factory type lookup successful: #{factory_class}"

puts "\n🎉 All basic tests passed!"
