# frozen_string_literal: true

require 'spec_helper'
require_relative 'mocks/http'
require_relative 'fixtures/accept_fixture_factory'

RSpec.describe Coarnotify::Client::COARNotifyClient do
  describe "#initialize" do
    it "can be constructed without arguments" do
      client = described_class.new
      expect(client.inbox_url).to be_nil
    end

    it "can be constructed with inbox URL" do
      client = described_class.new(inbox_url: "http://example.com/inbox")
      expect(client.inbox_url).to eq("http://example.com/inbox")
    end

    it "can be constructed with custom HTTP layer" do
      http_layer = Mocks::MockHttpLayer.new
      client = described_class.new(http_layer: http_layer)
      expect(client).to be_a(described_class)
    end

    it "can be constructed with both inbox URL and HTTP layer" do
      http_layer = Mocks::MockHttpLayer.new
      client = described_class.new(
        inbox_url: "http://example.com/inbox",
        http_layer: http_layer
      )
      expect(client.inbox_url).to eq("http://example.com/inbox")
    end
  end

  describe "#send" do
    context "when server responds with 201 Created" do
      it "returns CREATED response with location" do
        http_layer = Mocks::MockHttpLayer.new(
          status_code: 201,
          location: "http://example.com/location"
        )
        client = described_class.new(
          inbox_url: "http://example.com/inbox",
          http_layer: http_layer
        )

        # Create a valid Accept notification
        source = Fixtures::AcceptFixtureFactory.source
        accept = Coarnotify::Patterns::Accept.new(stream: source)

        response = client.send(accept)

        expect(response.action).to eq(Coarnotify::Client::NotifyResponse::CREATED)
        expect(response.location).to eq("http://example.com/location")
      end
    end

    context "when server responds with 202 Accepted" do
      it "returns ACCEPTED response without location" do
        http_layer = Mocks::MockHttpLayer.new(status_code: 202)
        client = described_class.new(
          inbox_url: "http://example.com/inbox",
          http_layer: http_layer
        )

        # Create a valid Accept notification
        source = Fixtures::AcceptFixtureFactory.source
        accept = Coarnotify::Patterns::Accept.new(stream: source)

        response = client.send(accept)

        expect(response.action).to eq(Coarnotify::Client::NotifyResponse::ACCEPTED)
        expect(response.location).to be_nil
      end
    end

    context "when server responds with unexpected status" do
      it "raises NotifyException" do
        http_layer = Mocks::MockHttpLayer.new(status_code: 400)
        client = described_class.new(
          inbox_url: "http://example.com/inbox",
          http_layer: http_layer
        )

        # Create a valid Accept notification
        source = Fixtures::AcceptFixtureFactory.source
        accept = Coarnotify::Patterns::Accept.new(stream: source)

        expect {
          client.send(accept)
        }.to raise_error(Coarnotify::NotifyException, "Unexpected response: 400")
      end
    end

    context "when no inbox URL is provided" do
      it "raises ArgumentError" do
        client = described_class.new

        # Create an accept without target inbox
        accept = Coarnotify::Patterns::Accept.new
        accept.origin = Coarnotify::Core::Notify::NotifyService.new
        accept.origin.id = "https://example.com/origin"

        accept.target = Coarnotify::Core::Notify::NotifyService.new
        accept.target.id = "https://example.com/target"
        # Don't set target.inbox

        accept.object = Coarnotify::Core::Notify::NotifyObject.new
        accept.object.id = "https://example.com/object"

        accept.in_reply_to = accept.object.id

        expect {
          client.send(accept)
        }.to raise_error(ArgumentError, /No inbox URL provided/)
      end
    end

    context "when validation is enabled and notification is invalid" do
      it "raises NotifyException" do
        client = described_class.new(inbox_url: "http://example.com/inbox")

        # Create an invalid notification (missing required fields)
        accept = Coarnotify::Patterns::Accept.new(validate_properties: false)
        accept.id = "https://example.com/invalid"
        # Don't set required origin, target, object - this will fail validation

        expect {
          client.send(accept, validate: true)
        }.to raise_error(Coarnotify::NotifyException, /Attempting to send invalid notification/)
      end
    end

    context "when validation is disabled" do
      it "sends notification even if invalid" do
        http_layer = Mocks::MockHttpLayer.new(status_code: 201)
        client = described_class.new(
          inbox_url: "http://example.com/inbox",
          http_layer: http_layer
        )

        # Create an invalid notification (missing required fields)
        accept = Coarnotify::Patterns::Accept.new(validate_properties: false)
        accept.id = "https://example.com/invalid"
        # Don't set required origin, target, object

        # Should not raise error when validation is disabled
        response = client.send(accept, validate: false)
        expect(response.action).to eq(Coarnotify::Client::NotifyResponse::CREATED)
      end
    end
  end
end
