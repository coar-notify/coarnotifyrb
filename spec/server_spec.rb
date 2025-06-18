# frozen_string_literal: true

require 'spec_helper'
require_relative 'fixtures/accept_fixture_factory'
require_relative 'fixtures/request_review_fixture_factory'

RSpec.describe "Server Components" do
  describe "COARNotifyReceipt" do
    it "can be created with status and location" do
      receipt = Coarnotify::Server::COARNotifyReceipt.new(201, "https://example.com/location")
      
      expect(receipt.status).to eq(201)
      expect(receipt.location).to eq("https://example.com/location")
    end

    it "can be created with just status" do
      receipt = Coarnotify::Server::COARNotifyReceipt.new(202)
      
      expect(receipt.status).to eq(202)
      expect(receipt.location).to be_nil
    end

    it "has correct status constants" do
      expect(Coarnotify::Server::COARNotifyReceipt::CREATED).to eq(201)
      expect(Coarnotify::Server::COARNotifyReceipt::ACCEPTED).to eq(202)
    end
  end

  describe "COARNotifyServiceBinding" do
    it "raises NotImplementedError for notification_received" do
      binding = Coarnotify::Server::COARNotifyServiceBinding.new
      
      expect {
        binding.notification_received(nil)
      }.to raise_error(NotImplementedError)
    end
  end

  describe "COARNotifyServerError" do
    it "can be created with status and message" do
      error = Coarnotify::Server::COARNotifyServerError.new(400, "Bad Request")
      
      expect(error.status).to eq(400)
      expect(error.message).to eq("Bad Request")
      expect(error.to_s).to eq("Bad Request")
    end
  end

  describe "COARNotifyServer" do
    let(:test_service_binding) do
      Class.new(Coarnotify::Server::COARNotifyServiceBinding) do
        def notification_received(notification)
          Coarnotify::Server::COARNotifyReceipt.new(
            Coarnotify::Server::COARNotifyReceipt::CREATED,
            "https://example.com/notifications/123"
          )
        end
      end.new
    end

    let(:server) { Coarnotify::Server::COARNotifyServer.new(test_service_binding) }

    it "can be created with a service binding" do
      expect(server).to be_a(Coarnotify::Server::COARNotifyServer)
    end

    context "when receiving valid JSON data" do
      it "processes the notification and returns receipt" do
        data = Fixtures::AcceptFixtureFactory.source
        
        receipt = server.receive(data)
        
        expect(receipt).to be_a(Coarnotify::Server::COARNotifyReceipt)
        expect(receipt.status).to eq(201)
        expect(receipt.location).to eq("https://example.com/notifications/123")
      end
    end

    context "when receiving JSON string" do
      it "parses and processes the notification" do
        data = Fixtures::AcceptFixtureFactory.source
        json_string = JSON.generate(data)
        
        receipt = server.receive(json_string)
        
        expect(receipt).to be_a(Coarnotify::Server::COARNotifyReceipt)
        expect(receipt.status).to eq(201)
      end
    end

    context "when validation is enabled" do
      it "validates the notification before processing" do
        # Create invalid data
        data = {
          "type" => "Accept",
          "id" => "invalid uri"
        }
        
        expect {
          server.receive(data, validate: true)
        }.to raise_error(Coarnotify::Server::COARNotifyServerError) do |error|
          expect(error.status).to eq(400)
          expect(error.message).to eq("Invalid notification")
        end
      end
    end

    context "when validation is disabled" do
      it "processes notification without validation" do
        # Create invalid data that would normally fail validation
        data = {
          "type" => "Accept",
          "id" => "invalid uri"
        }
        
        # Should not raise error when validation is disabled
        receipt = server.receive(data, validate: false)
        expect(receipt).to be_a(Coarnotify::Server::COARNotifyReceipt)
      end
    end

    context "when service binding raises an error" do
      let(:error_service_binding) do
        Class.new(Coarnotify::Server::COARNotifyServiceBinding) do
          def notification_received(notification)
            raise StandardError, "Service error"
          end
        end.new
      end

      let(:error_server) { Coarnotify::Server::COARNotifyServer.new(error_service_binding) }

      it "allows the error to propagate" do
        data = Fixtures::AcceptFixtureFactory.source
        
        expect {
          error_server.receive(data)
        }.to raise_error(StandardError, "Service error")
      end
    end

    context "when notification type is not recognized" do
      it "raises NotifyException" do
        data = {
          "type" => "UnknownType",
          "id" => "https://example.com/test"
        }
        
        expect {
          server.receive(data)
        }.to raise_error(Coarnotify::NotifyException, /No matching pattern found/)
      end
    end
  end

  describe "Integration with service binding" do
    let(:tracking_service_binding) do
      Class.new(Coarnotify::Server::COARNotifyServiceBinding) do
        attr_reader :received_notifications

        def initialize
          @received_notifications = []
        end

        def notification_received(notification)
          @received_notifications << notification
          
          case notification
          when Coarnotify::Patterns::Accept
            Coarnotify::Server::COARNotifyReceipt.new(
              Coarnotify::Server::COARNotifyReceipt::CREATED,
              "https://example.com/accept/#{notification.id}"
            )
          when Coarnotify::Patterns::RequestReview
            Coarnotify::Server::COARNotifyReceipt.new(
              Coarnotify::Server::COARNotifyReceipt::ACCEPTED
            )
          else
            Coarnotify::Server::COARNotifyReceipt.new(
              Coarnotify::Server::COARNotifyReceipt::CREATED,
              "https://example.com/generic/#{notification.id}"
            )
          end
        end
      end.new
    end

    let(:server) { Coarnotify::Server::COARNotifyServer.new(tracking_service_binding) }

    it "correctly identifies and processes Accept notifications" do
      data = Fixtures::AcceptFixtureFactory.source
      
      receipt = server.receive(data)
      
      expect(receipt.status).to eq(201)
      expect(receipt.location).to include("/accept/")
      expect(tracking_service_binding.received_notifications.length).to eq(1)
      expect(tracking_service_binding.received_notifications.first).to be_a(Coarnotify::Patterns::Accept)
    end

    it "correctly identifies and processes RequestReview notifications" do
      data = Fixtures::RequestReviewFixtureFactory.source
      
      receipt = server.receive(data)
      
      expect(receipt.status).to eq(202)
      expect(receipt.location).to be_nil
      expect(tracking_service_binding.received_notifications.length).to eq(1)
      expect(tracking_service_binding.received_notifications.first).to be_a(Coarnotify::Patterns::RequestReview)
    end
  end
end
