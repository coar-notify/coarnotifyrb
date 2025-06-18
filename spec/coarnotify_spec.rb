# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Coarnotify do
  it "has a version number" do
    expect(Coarnotify::VERSION).not_to be nil
    expect(Coarnotify::VERSION).to match(/\d+\.\d+\.\d+/)
  end

  describe "module convenience methods" do
    it "can create a client" do
      client = Coarnotify.client
      expect(client).to be_a(Coarnotify::Client::COARNotifyClient)
    end

    it "can create a client with inbox URL" do
      client = Coarnotify.client(inbox_url: "https://example.com/inbox")
      expect(client).to be_a(Coarnotify::Client::COARNotifyClient)
      expect(client.inbox_url).to eq("https://example.com/inbox")
    end

    it "can create a server" do
      service_binding = double("service_binding")
      server = Coarnotify.server(service_binding)
      expect(server).to be_a(Coarnotify::Server::COARNotifyServer)
    end

    it "can create patterns from hash data" do
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
      expect(pattern).to be_a(Coarnotify::Patterns::Accept)
      expect(pattern.id).to eq("https://example.com/notification")
      expect(pattern.origin.id).to eq("https://example.com/origin")
    end

    it "can create patterns from JSON string" do
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

      json_string = JSON.generate(data)
      pattern = Coarnotify.from_json(json_string)
      expect(pattern).to be_a(Coarnotify::Patterns::Accept)
      expect(pattern.id).to eq("https://example.com/notification")
    end
  end

  describe "pattern creation and validation" do
    it "can create an Accept pattern" do
      accept = Coarnotify::Patterns::Accept.new
      expect(accept).to be_a(Coarnotify::Patterns::Accept)
      expect(accept.type).to eq("Accept")
      expect(accept.id).to match(/^urn:uuid:[0-9a-f-]+$/)
    end

    it "can create a RequestReview pattern" do
      request_review = Coarnotify::Patterns::RequestReview.new
      expect(request_review).to be_a(Coarnotify::Patterns::RequestReview)
      expect(request_review.type).to eq(["Offer", "coar-notify:ReviewAction"])
    end

    it "can validate complete patterns" do
      accept = Coarnotify::Patterns::Accept.new

      # Should fail validation without required properties
      expect { accept.validate }.to raise_error(Coarnotify::ValidationError)

      # Add required properties
      accept.origin = Coarnotify::Core::Notify::NotifyService.new
      accept.origin.id = "https://example.com/origin"

      accept.target = Coarnotify::Core::Notify::NotifyService.new
      accept.target.id = "https://example.com/target"

      accept.object = Coarnotify::Core::Notify::NotifyObject.new
      accept.object.id = "https://example.com/object"

      # For Accept pattern, inReplyTo must match object.id
      accept.in_reply_to = accept.object.id

      # Should now pass validation
      expect(accept.validate).to be true
    end

    it "can convert patterns to JSON-LD" do
      accept = Coarnotify::Patterns::Accept.new
      accept.origin = Coarnotify::Core::Notify::NotifyService.new
      accept.origin.id = "https://example.com/origin"

      json_ld = accept.to_jsonld
      expect(json_ld).to be_a(Hash)
      expect(json_ld["@context"]).to be_a(Array)
      expect(json_ld["type"]).to eq("Accept")
      expect(json_ld["origin"]["id"]).to eq("https://example.com/origin")
    end
  end

  describe "all pattern types" do
    let(:pattern_classes) do
      [
        Coarnotify::Patterns::Accept,
        Coarnotify::Patterns::Reject,
        Coarnotify::Patterns::TentativelyAccept,
        Coarnotify::Patterns::TentativelyReject,
        Coarnotify::Patterns::RequestReview,
        Coarnotify::Patterns::RequestEndorsement,
        Coarnotify::Patterns::AnnounceReview,
        Coarnotify::Patterns::AnnounceEndorsement,
        Coarnotify::Patterns::AnnounceRelationship,
        Coarnotify::Patterns::AnnounceServiceResult,
        Coarnotify::Patterns::UndoOffer,
        Coarnotify::Patterns::UnprocessableNotification
      ]
    end

    it "can instantiate all pattern types" do
      pattern_classes.each do |pattern_class|
        pattern = pattern_class.new
        expect(pattern).to be_a(pattern_class)
        expect(pattern.type).not_to be_nil
        expect(pattern.id).to match(/^urn:uuid:[0-9a-f-]+$/)
      end
    end

    it "has correct type constants for all patterns" do
      expect(Coarnotify::Patterns::Accept.type_constant).to eq("Accept")
      expect(Coarnotify::Patterns::Reject.type_constant).to eq("Reject")
      expect(Coarnotify::Patterns::TentativelyAccept.type_constant).to eq("TentativeAccept")
      expect(Coarnotify::Patterns::TentativelyReject.type_constant).to eq("TentativeReject")
      expect(Coarnotify::Patterns::RequestReview.type_constant).to eq(["Offer", "coar-notify:ReviewAction"])
      expect(Coarnotify::Patterns::RequestEndorsement.type_constant).to eq(["Offer", "coar-notify:EndorsementAction"])
      expect(Coarnotify::Patterns::AnnounceReview.type_constant).to eq(["Announce", "coar-notify:ReviewAction"])
      expect(Coarnotify::Patterns::AnnounceEndorsement.type_constant).to eq(["Announce", "coar-notify:EndorsementAction"])
      expect(Coarnotify::Patterns::AnnounceRelationship.type_constant).to eq(["Announce", "coar-notify:RelationshipAction"])
      expect(Coarnotify::Patterns::AnnounceServiceResult.type_constant).to eq(["Announce", "coar-notify:IngestAction"])
      expect(Coarnotify::Patterns::UndoOffer.type_constant).to eq("Undo")
      expect(Coarnotify::Patterns::UnprocessableNotification.type_constant).to eq("coar-notify:UnprocessableNotification")
    end
  end

  describe "factory integration" do
    it "can identify patterns by type" do
      accept_class = Coarnotify::Factory::COARNotifyFactory.get_by_types("Accept")
      expect(accept_class).to eq(Coarnotify::Patterns::Accept)

      review_class = Coarnotify::Factory::COARNotifyFactory.get_by_types(["Offer", "coar-notify:ReviewAction"])
      expect(review_class).to eq(Coarnotify::Patterns::RequestReview)
    end

    it "integrates with convenience methods" do
      data = {
        "@context" => ["https://www.w3.org/ns/activitystreams"],
        "type" => ["Offer", "coar-notify:ReviewAction"],
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
        }
      }

      pattern = Coarnotify.from_hash(data, validate_stream_on_construct: false)
      expect(pattern).to be_a(Coarnotify::Patterns::RequestReview)
    end
  end
end
