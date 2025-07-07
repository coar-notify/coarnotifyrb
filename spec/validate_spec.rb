# frozen_string_literal: true

require 'spec_helper'
require_relative 'fixtures/accept_fixture_factory'
require_relative 'fixtures/request_review_fixture_factory'

RSpec.describe "Validation" do
  describe "structural validation" do
    context "when pattern is completely empty" do
      it "raises ValidationError with required field errors" do
        pattern = Coarnotify::Core::Notify::NotifyPattern.new
        pattern.id = nil  # Remove auto-generated values
        pattern.type = nil

        expect { pattern.validate }.to raise_error(Coarnotify::ValidationError) do |error|
          errors = error.errors
          expect(errors).to have_key(Coarnotify::Core::ActivityStreams2::Properties::ID)
          expect(errors).to have_key(Coarnotify::Core::ActivityStreams2::Properties::TYPE)
          expect(errors).to have_key(Coarnotify::Core::ActivityStreams2::Properties::OBJECT)
          expect(errors).to have_key(Coarnotify::Core::ActivityStreams2::Properties::TARGET)
          expect(errors).to have_key(Coarnotify::Core::ActivityStreams2::Properties::ORIGIN)
        end
      end
    end

    context "when pattern has basic required fields" do
      it "raises ValidationError for missing nested objects" do
        pattern = Coarnotify::Core::Notify::NotifyPattern.new

        expect { pattern.validate }.to raise_error(Coarnotify::ValidationError) do |error|
          errors = error.errors
          expect(errors).not_to have_key(Coarnotify::Core::ActivityStreams2::Properties::ID)
          expect(errors).not_to have_key(Coarnotify::Core::ActivityStreams2::Properties::TYPE)
          expect(errors).to have_key(Coarnotify::Core::ActivityStreams2::Properties::OBJECT)
          expect(errors).to have_key(Coarnotify::Core::ActivityStreams2::Properties::TARGET)
          expect(errors).to have_key(Coarnotify::Core::ActivityStreams2::Properties::ORIGIN)
        end
      end
    end

    context "when pattern has all required objects" do
      it "validates successfully" do
        pattern = Coarnotify::Core::Notify::NotifyPattern.new
        
        pattern.target = Coarnotify::Core::Notify::NotifyService.new
        pattern.target.id = "https://example.com/target"
        
        pattern.origin = Coarnotify::Core::Notify::NotifyService.new
        pattern.origin.id = "https://example.com/origin"
        
        pattern.object = Coarnotify::Core::Notify::NotifyObject.new
        pattern.object.id = "https://example.com/object"

        expect(pattern.validate).to be true
      end
    end

    context "when pattern has invalid nested objects" do
      it "raises ValidationError with nested errors" do
        pattern = Coarnotify::Core::Notify::NotifyPattern.new
        
        # Create invalid nested objects
        pattern.target = Coarnotify::Core::Notify::NotifyService.new(
          stream: { "whatever" => "value" },
          validate_stream_on_construct: false
        )
        pattern.origin = Coarnotify::Core::Notify::NotifyService.new(
          stream: { "another" => "junk" },
          validate_stream_on_construct: false
        )
        pattern.object = Coarnotify::Core::Notify::NotifyObject.new(
          stream: { "yet" => "more" },
          validate_stream_on_construct: false
        )

        expect { pattern.validate }.to raise_error(Coarnotify::ValidationError) do |error|
          errors = error.errors
          expect(errors).not_to have_key(Coarnotify::Core::ActivityStreams2::Properties::ID)
          expect(errors).not_to have_key(Coarnotify::Core::ActivityStreams2::Properties::TYPE)
          expect(errors).not_to have_key(Coarnotify::Core::ActivityStreams2::Properties::OBJECT)
          expect(errors).to have_key(Coarnotify::Core::ActivityStreams2::Properties::TARGET)
          expect(errors).to have_key(Coarnotify::Core::ActivityStreams2::Properties::ORIGIN)
        end
      end
    end
  end

  describe "validation modes" do
    it "validates on construction when validate_stream_on_construct is true" do
      valid_data = create_valid_notify_data
      pattern = Coarnotify::Core::Notify::NotifyPattern.new(
        stream: valid_data,
        validate_stream_on_construct: true
      )
      expect(pattern).to be_a(Coarnotify::Core::Notify::NotifyPattern)

      invalid_data = create_valid_notify_data
      invalid_data["id"] = "http://example.com/^path"
      
      expect {
        Coarnotify::Core::Notify::NotifyPattern.new(
          stream: invalid_data,
          validate_stream_on_construct: true
        )
      }.to raise_error(Coarnotify::ValidationError) do |error|
        expect(error.errors).to have_key(Coarnotify::Core::ActivityStreams2::Properties::ID)
      end
    end

    it "skips validation on construction when validate_stream_on_construct is false" do
      valid_data = create_valid_notify_data
      pattern = Coarnotify::Core::Notify::NotifyPattern.new(
        stream: valid_data,
        validate_stream_on_construct: false
      )
      expect(pattern).to be_a(Coarnotify::Core::Notify::NotifyPattern)

      invalid_data = create_valid_notify_data
      invalid_data["id"] = "http://example.com/^path"
      
      # Should not raise error during construction
      pattern = Coarnotify::Core::Notify::NotifyPattern.new(
        stream: invalid_data,
        validate_stream_on_construct: false
      )
      expect(pattern).to be_a(Coarnotify::Core::Notify::NotifyPattern)
    end

    it "validates properties when validate_properties is true" do
      pattern = Coarnotify::Core::Notify::NotifyPattern.new(validate_properties: true)
      
      # Valid ID should work
      pattern.id = "urn:uuid:4fb3af44-d4f8-4226-9475-2d09c2d8d9e0"
      
      # Invalid ID should raise error
      expect {
        pattern.id = "http://example.com/^path"
      }.to raise_error(ArgumentError)
    end

    it "skips property validation when validate_properties is false" do
      pattern = Coarnotify::Core::Notify::NotifyPattern.new(validate_properties: false)
      
      # Valid ID should work
      pattern.id = "urn:uuid:4fb3af44-d4f8-4226-9475-2d09c2d8d9e0"
      
      # Invalid ID should also work (no validation)
      pattern.id = "http://example.com/^path"
      expect(pattern.id).to eq("http://example.com/^path")
      
      # But explicit validation should still catch the error
      expect { pattern.validate }.to raise_error(Coarnotify::ValidationError) do |error|
        expect(error.errors).to have_key(Coarnotify::Core::ActivityStreams2::Properties::ID)
      end
    end
  end

  describe "ID property validation" do
    let(:pattern) { Coarnotify::Core::Notify::NotifyPattern.new }

    it "rejects invalid URI schemes" do
      expect {
        pattern.id = "9whatever:none"
      }.to raise_error(ArgumentError, /Invalid URI scheme/)
    end

    it "rejects invalid URI authorities" do
      expect {
        pattern.id = "http://wibble/stuff"
      }.to raise_error(ArgumentError, /Invalid URI authority/)
    end

    it "rejects invalid URI paths" do
      expect {
        pattern.id = "http://example.com/^path"
      }.to raise_error(ArgumentError, /Invalid URI path/)
    end

    it "rejects invalid URI queries" do
      expect {
        pattern.id = "http://example.com/path/here/?^=what"
      }.to raise_error(ArgumentError, /Invalid URI query/)
    end

    it "rejects invalid URI fragments" do
      expect {
        pattern.id = "http://example.com/path/here/?you=what#^frag"
      }.to raise_error(ArgumentError, /Invalid URI fragment/)
    end

    it "accepts valid URIs" do
      valid_uris = [
        "https://john.doe@www.example.com:1234/forum/questions/?tag=networking&order=newest#top",
        "https://john.doe@www.example.com:1234/forum/questions/?tag=networking&order=newest#:~:text=whatever",
        "ldap://[2001:db8::7]/c=GB?objectClass?one",
        "mailto:John.Doe@example.com",
        "news:comp.infosystems.www.servers.unix",
        "tel:+1-816-555-1212",
        "telnet://192.0.2.16:80/",
        "urn:oasis:names:specification:docbook:dtd:xml:4.1.2",
        "urn:uuid:4fb3af44-d4f8-4226-9475-2d09c2d8d9e0",
        "https://generic-service.com/system",
        "https://generic-service.com/system/inbox/"
      ]

      valid_uris.each do |uri|
        expect { pattern.id = uri }.not_to raise_error
        expect(pattern.id).to eq(uri)
      end
    end
  end

  describe "URL validation" do
    it "accepts valid HTTP and HTTPS URLs" do
      valid_urls = [
        "http://example.com",
        "https://example.com",
        "http://example.com/path",
        "https://example.com/path?query=value",
        "http://example.com:8080/path#fragment"
      ]

      valid_urls.each do |url|
        expect(Coarnotify::Validate.url(nil, url)).to be true
      end
    end

    it "rejects non-HTTP URLs" do
      expect {
        Coarnotify::Validate.url(nil, "ftp://example.com")
      }.to raise_error(ArgumentError, /URL scheme must be http or https/)
    end

    it "rejects malformed URLs" do
      expect {
        Coarnotify::Validate.url(nil, "http:/example.com")
      }.to raise_error(ArgumentError)

      expect {
        Coarnotify::Validate.url(nil, "http://domain/path")
      }.to raise_error(ArgumentError)

      expect {
        Coarnotify::Validate.url(nil, "http://example.com/path^wrong")
      }.to raise_error(ArgumentError)
    end
  end

  describe "one_of validator" do
    let(:validator) { Coarnotify::Validate.one_of(["a", "b", "c"]) }

    it "accepts valid values" do
      expect(validator.call(nil, "a")).to be true
      expect(validator.call(nil, "b")).to be true
      expect(validator.call(nil, "c")).to be true
    end

    it "rejects invalid values" do
      expect {
        validator.call(nil, "d")
      }.to raise_error(ArgumentError, /is not one of the valid values/)
    end

    it "rejects arrays (expects singular values)" do
      expect {
        validator.call(nil, ["a", "b"])
      }.to raise_error(ArgumentError)
    end
  end

  describe "contains validator" do
    let(:validator) { Coarnotify::Validate.contains("a") }

    it "accepts arrays containing the required value" do
      expect(validator.call(nil, ["a", "b", "c"])).to be true
    end

    it "rejects arrays not containing the required value" do
      expect {
        validator.call(nil, ["b", "c", "d"])
      }.to raise_error(ArgumentError, /does not contain the required value/)
    end
  end

  describe "at_least_one_of validator" do
    let(:validator) { Coarnotify::Validate.at_least_one_of(["a", "b", "c"]) }

    it "accepts valid single values" do
      expect(validator.call(nil, "a")).to be true
      expect(validator.call(nil, "b")).to be true
      expect(validator.call(nil, "c")).to be true
    end

    it "rejects invalid single values" do
      expect {
        validator.call(nil, "d")
      }.to raise_error(ArgumentError, /is not one of the valid values/)
    end

    it "accepts arrays with at least one valid value" do
      expect(validator.call(nil, ["a", "d"])).to be true
    end
  end

  describe "Accept pattern validation" do
    it "validates a valid Accept pattern" do
      source = Fixtures::AcceptFixtureFactory.source
      accept = Coarnotify::Patterns::Accept.new(stream: source)
      expect(accept.validate).to be true
    end

    it "validates base properties" do
      source = Fixtures::AcceptFixtureFactory.source
      accept = Coarnotify::Patterns::Accept.new(stream: source)

      # Test invalid ID
      expect {
        accept.id = "not a uri"
      }.to raise_error(ArgumentError)

      # Test invalid inReplyTo
      expect {
        accept.in_reply_to = "not a uri"
      }.to raise_error(ArgumentError)

      # Test invalid origin ID (not HTTP)
      expect {
        accept.origin.id = "urn:uuid:4fb3af44-d4f8-4226-9475-2d09c2d8d9e0"
      }.to raise_error(ArgumentError)

      # Test invalid origin inbox
      expect {
        accept.origin.inbox = "not a uri"
      }.to raise_error(ArgumentError)

      # Test invalid target ID (not HTTP)
      expect {
        accept.target.id = "urn:uuid:4fb3af44-d4f8-4226-9475-2d09c2d8d9e0"
      }.to raise_error(ArgumentError)

      # Test invalid target inbox
      expect {
        accept.target.inbox = "not a uri"
      }.to raise_error(ArgumentError)

      # Test that type validation works (Accept pattern should maintain its type)
      expect(accept.type).to eq("Accept")
    end

    it "raises ValidationError for completely invalid Accept data" do
      invalid_source = Fixtures::AcceptFixtureFactory.invalid
      expect {
        Coarnotify::Patterns::Accept.new(stream: invalid_source)
      }.to raise_error(Coarnotify::ValidationError)
    end
  end

  describe "RequestReview pattern validation" do
    it "validates a valid RequestReview pattern" do
      source = Fixtures::RequestReviewFixtureFactory.source
      request_review = Coarnotify::Patterns::RequestReview.new(stream: source)
      expect(request_review.validate).to be true
    end

    it "validates base properties" do
      source = Fixtures::RequestReviewFixtureFactory.source
      request_review = Coarnotify::Patterns::RequestReview.new(stream: source)

      # Test that type validation works (RequestReview pattern should maintain both types)
      expect(request_review.type).to eq(["Offer", "coar-notify:ReviewAction"])
    end

    it "raises ValidationError for completely invalid RequestReview data" do
      invalid_source = Fixtures::RequestReviewFixtureFactory.invalid
      expect {
        Coarnotify::Patterns::RequestReview.new(stream: invalid_source)
      }.to raise_error(Coarnotify::ValidationError)
    end
  end

  private

  def create_valid_notify_data
    {
      "id" => "urn:uuid:4fb3af44-d4f8-4226-9475-2d09c2d8d9e0",
      "type" => "Object",
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
      }
    }
  end
end
