# frozen_string_literal: true

require 'spec_helper'
require_relative '../fixtures/accept_fixture_factory'
require_relative '../fixtures/request_review_fixture_factory'
require_relative '../mocks/http'

# Integration tests for the COAR Notify client
# These tests require a running COAR Notify inbox server
# Set COAR_NOTIFY_INBOX_URL environment variable to run these tests
RSpec.describe "Client Integration", :integration do
  let(:inbox_url) { ENV['COAR_NOTIFY_INBOX_URL'] || 'http://example.com/inbox' }
  let(:use_mock_http) { inbox_url.include?('example.com') }
  let(:mock_http) { Mocks::MockHttpLayer.new(status_code: 201, location: "#{inbox_url}/notifications/123") }
  let(:client) do
    if use_mock_http
      Coarnotify::Client::COARNotifyClient.new(inbox_url: inbox_url, http_layer: mock_http)
    else
      Coarnotify::Client::COARNotifyClient.new(inbox_url: inbox_url)
    end
  end

  before(:all) do
    # Check if we have a valid COAR Notify inbox or if we're using mock
    inbox_available = false

    if ENV['COAR_NOTIFY_INBOX_URL']
      # Test if the provided URL is actually a working COAR Notify inbox
      begin
        uri = URI.parse(ENV['COAR_NOTIFY_INBOX_URL'])
        if uri.host
          if uri.host == 'example.com'
            # Use mock HTTP for example.com
            inbox_available = true
          elsif uri.host != 'localhost' || system("curl -s #{ENV['COAR_NOTIFY_INBOX_URL']} > /dev/null 2>&1")
            inbox_available = true
          end
        end
      rescue URI::InvalidURIError
        # Invalid URL format
      end
    else
      # Default to example.com with mock HTTP
      inbox_available = true
    end

    unless inbox_available
      skip "No working COAR Notify inbox available. Set COAR_NOTIFY_INBOX_URL to a real inbox URL or use example.com for mock testing"
    end
  end

  describe "sending Accept notifications" do
    it "successfully sends Accept notification and receives CREATED response" do
      source = Fixtures::AcceptFixtureFactory.source
      accept = Coarnotify::Patterns::Accept.new(stream: source)
      
      response = client.send(accept)
      
      expect(response.action).to eq(Coarnotify::Client::NotifyResponse::CREATED)
      expect(response.location).not_to be_nil
      puts "Accept notification created at: #{response.location}"
    end
  end

  describe "sending RequestReview notifications" do
    it "successfully sends RequestReview notification and receives CREATED response" do
      source = Fixtures::RequestReviewFixtureFactory.source
      request_review = Coarnotify::Patterns::RequestReview.new(stream: source)
      
      response = client.send(request_review)
      
      expect(response.action).to eq(Coarnotify::Client::NotifyResponse::CREATED)
      expect(response.location).not_to be_nil
      puts "RequestReview notification created at: #{response.location}"
    end
  end

  describe "sending all pattern types" do
    let(:patterns_and_fixtures) do
      [
        [Coarnotify::Patterns::Accept, Fixtures::AcceptFixtureFactory],
        [Coarnotify::Patterns::RequestReview, Fixtures::RequestReviewFixtureFactory]
        # Add more patterns as fixtures are created
      ]
    end

    it "successfully sends all supported pattern types" do
      patterns_and_fixtures.each do |pattern_class, fixture_factory|
        source = fixture_factory.source
        pattern = pattern_class.new(stream: source)

        # Create a fresh client for each pattern to ensure clean mock state
        test_client = if use_mock_http
          Coarnotify::Client::COARNotifyClient.new(
            inbox_url: inbox_url,
            http_layer: Mocks::MockHttpLayer.new(status_code: 201, location: "#{inbox_url}/#{pattern_class.name.split('::').last.downcase}/123")
          )
        else
          client
        end

        response = test_client.send(pattern)

        expect(response.action).to eq(Coarnotify::Client::NotifyResponse::CREATED)
        expect(response.location).not_to be_nil

        puts "#{pattern_class.name.split('::').last} notification created at: #{response.location}"
      end
    end
  end

  describe "error handling" do
    it "handles invalid inbox URLs gracefully" do
      # Use a URL that will definitely fail (no mock for this one)
      invalid_client = Coarnotify::Client::COARNotifyClient.new(inbox_url: 'http://invalid-url-that-does-not-exist-12345.com/inbox')
      source = Fixtures::AcceptFixtureFactory.source
      accept = Coarnotify::Patterns::Accept.new(stream: source)

      expect {
        invalid_client.send(accept)
      }.to raise_error(StandardError) # Could be various network errors
    end

    it "handles malformed notifications" do
      # Create a notification with missing required fields
      accept = Coarnotify::Patterns::Accept.new
      # Don't set required fields - this should fail validation
      
      expect {
        client.send(accept, validate: true)
      }.to raise_error(Coarnotify::NotifyException, /Attempting to send invalid notification/)
    end
  end

  describe "JSON-LD serialization" do
    it "produces valid JSON-LD that can be round-tripped" do
      source = Fixtures::AcceptFixtureFactory.source
      original = Coarnotify::Patterns::Accept.new(stream: source)
      
      # Convert to JSON-LD
      json_ld = original.to_jsonld
      json_string = JSON.generate(json_ld)
      
      # Parse back from JSON
      parsed_data = JSON.parse(json_string)
      reconstructed = Coarnotify::Factory::COARNotifyFactory.get_by_object(parsed_data)
      
      expect(reconstructed).to be_a(Coarnotify::Patterns::Accept)
      expect(reconstructed.id).to eq(original.id)
      expect(reconstructed.type).to eq(original.type)
      expect(reconstructed.origin.id).to eq(original.origin.id)
      expect(reconstructed.target.id).to eq(original.target.id)
      expect(reconstructed.object.id).to eq(original.object.id)
    end
  end

  describe "validation integration" do
    it "validates complete notification workflows" do
      # Create a RequestReview
      request_source = Fixtures::RequestReviewFixtureFactory.source
      request_review = Coarnotify::Patterns::RequestReview.new(stream: request_source)
      
      # Send it
      request_response = client.send(request_review)
      expect(request_response.action).to eq(Coarnotify::Client::NotifyResponse::CREATED)
      
      # Create an Accept in response
      accept = Coarnotify::Patterns::Accept.new
      accept.origin = request_review.target  # Response comes from the target
      accept.target = request_review.origin  # Goes back to the origin
      accept.object = request_review         # References the original request
      accept.in_reply_to = request_review.id # Must match for Accept pattern
      
      # Validate the Accept
      expect(accept.validate).to be true
      
      # Send the Accept
      accept_response = client.send(accept)
      expect(accept_response.action).to eq(Coarnotify::Client::NotifyResponse::CREATED)
      
      puts "Request-Accept workflow completed:"
      puts "  RequestReview: #{request_response.location}"
      puts "  Accept: #{accept_response.location}"
    end
  end
end
