#!/usr/bin/env ruby
# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

puts "Testing full library loading..."

require 'coarnotify'
puts "✓ Full library loaded successfully!"
puts "✓ Version: #{Coarnotify::VERSION}"

# Test convenience methods
client = Coarnotify.client
puts "✓ Convenience client method works"

# Test creating patterns from data
data = {
  "@context" => ["https://www.w3.org/ns/activitystreams"],
  "type" => "Accept",
  "id" => "https://example.com/notification",
  "origin" => {
    "id" => "https://example.com/origin",
    "type" => "Service"
  },
  "target" => {
    "id" => "https://example.com/target", 
    "type" => "Service"
  },
  "object" => {
    "id" => "https://example.com/object"
  },
  "inReplyTo" => "https://example.com/object"
}

pattern = Coarnotify.from_hash(data)
puts "✓ Pattern created from hash: #{pattern.class}"
puts "✓ Pattern ID: #{pattern.id}"
puts "✓ Pattern origin ID: #{pattern.origin.id}"

# Test JSON conversion
json_str = JSON.generate(data)
pattern_from_json = Coarnotify.from_json(json_str)
puts "✓ Pattern created from JSON: #{pattern_from_json.class}"

puts "\n🎉 Full library test passed!"
