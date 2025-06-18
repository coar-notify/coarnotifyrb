# frozen_string_literal: true

require 'spec_helper'
require_relative 'fixtures/accept_fixture_factory'
require_relative 'fixtures/request_review_fixture_factory'

RSpec.describe "Model Objects" do
  describe "ActivityStream" do
    it "can be created empty" do
      stream = Coarnotify::Core::ActivityStreams2::ActivityStream.new
      expect(stream.doc).to eq({})
      expect(stream.context).to eq([])
    end

    it "can be created with data" do
      data = {
        "@context" => ["https://www.w3.org/ns/activitystreams"],
        "type" => "Accept",
        "id" => "test"
      }
      stream = Coarnotify::Core::ActivityStreams2::ActivityStream.new(data)
      
      expect(stream.context).to eq(["https://www.w3.org/ns/activitystreams"])
      expect(stream.doc["type"]).to eq("Accept")
      expect(stream.doc["id"]).to eq("test")
    end

    it "can set and get properties" do
      stream = Coarnotify::Core::ActivityStreams2::ActivityStream.new
      
      stream.set_property("type", "Accept")
      expect(stream.get_property("type")).to eq("Accept")
      
      stream.set_property(["id", "https://example.com/ns"], "test-id")
      expect(stream.get_property(["id", "https://example.com/ns"])).to eq("test-id")
    end

    it "registers namespaces when setting properties" do
      stream = Coarnotify::Core::ActivityStreams2::ActivityStream.new
      
      stream.set_property(["test", "https://example.com/ns"], "value")
      expect(stream.context).to include("https://example.com/ns")
    end

    it "converts to JSON-LD" do
      stream = Coarnotify::Core::ActivityStreams2::ActivityStream.new
      stream.set_property("type", "Accept")
      stream.set_property("id", "test")
      
      json_ld = stream.to_jsonld
      expect(json_ld["@context"]).to be_a(Array)
      expect(json_ld["type"]).to eq("Accept")
      expect(json_ld["id"]).to eq("test")
    end
  end

  describe "NotifyBase" do
    it "generates UUID for id if not provided" do
      base = Coarnotify::Core::Notify::NotifyBase.new
      expect(base.id).to match(/^urn:uuid:[0-9a-f-]+$/)
    end

    it "preserves provided id" do
      stream = { "id" => "https://example.com/test-id", "type" => "Object" }
      base = Coarnotify::Core::Notify::NotifyBase.new(stream: stream, validate_stream_on_construct: false)
      expect(base.id).to eq("https://example.com/test-id")
    end

    it "can set and get properties" do
      base = Coarnotify::Core::Notify::NotifyBase.new
      
      base.set_property("test", "value")
      expect(base.get_property("test")).to eq("value")
    end

    it "validates properties when validate_properties is true" do
      base = Coarnotify::Core::Notify::NotifyBase.new(validate_properties: true)
      
      expect {
        base.id = "invalid uri"
      }.to raise_error(ArgumentError)
    end

    it "skips property validation when validate_properties is false" do
      base = Coarnotify::Core::Notify::NotifyBase.new(validate_properties: false)
      
      base.id = "invalid uri"
      expect(base.id).to eq("invalid uri")
    end
  end

  describe "NotifyPattern" do
    it "has correct type constant" do
      expect(Coarnotify::Core::Notify::NotifyPattern.type_constant).to eq("Object")
    end

    it "can set and get origin" do
      pattern = Coarnotify::Core::Notify::NotifyPattern.new
      
      origin = Coarnotify::Core::Notify::NotifyService.new
      origin.id = "https://example.com/origin"
      
      pattern.origin = origin
      expect(pattern.origin.id).to eq("https://example.com/origin")
    end

    it "can set and get target" do
      pattern = Coarnotify::Core::Notify::NotifyPattern.new
      
      target = Coarnotify::Core::Notify::NotifyService.new
      target.id = "https://example.com/target"
      
      pattern.target = target
      expect(pattern.target.id).to eq("https://example.com/target")
    end

    it "can set and get object" do
      pattern = Coarnotify::Core::Notify::NotifyPattern.new
      
      object = Coarnotify::Core::Notify::NotifyObject.new
      object.id = "https://example.com/object"
      
      pattern.object = object
      expect(pattern.object.id).to eq("https://example.com/object")
    end

    it "can set and get actor" do
      pattern = Coarnotify::Core::Notify::NotifyPattern.new
      
      actor = Coarnotify::Core::Notify::NotifyActor.new
      actor.id = "https://example.com/actor"
      
      pattern.actor = actor
      expect(pattern.actor.id).to eq("https://example.com/actor")
    end

    it "can set and get context" do
      pattern = Coarnotify::Core::Notify::NotifyPattern.new
      
      context = Coarnotify::Core::Notify::NotifyObject.new
      context.id = "https://example.com/context"
      
      pattern.context = context
      expect(pattern.context.id).to eq("https://example.com/context")
    end

    it "can set and get inReplyTo" do
      pattern = Coarnotify::Core::Notify::NotifyPattern.new
      
      pattern.in_reply_to = "https://example.com/reply-to"
      expect(pattern.in_reply_to).to eq("https://example.com/reply-to")
    end
  end

  describe "NotifyService" do
    it "has default type of Service" do
      service = Coarnotify::Core::Notify::NotifyService.new
      expect(service.type).to eq("Service")
    end

    it "can set and get inbox" do
      service = Coarnotify::Core::Notify::NotifyService.new
      
      service.inbox = "https://example.com/inbox"
      expect(service.inbox).to eq("https://example.com/inbox")
    end
  end

  describe "NotifyObject" do
    it "can set and get cite_as" do
      object = Coarnotify::Core::Notify::NotifyObject.new
      
      object.cite_as = "https://doi.org/10.5555/12345680"
      expect(object.cite_as).to eq("https://doi.org/10.5555/12345680")
    end

    it "can set and get item" do
      object = Coarnotify::Core::Notify::NotifyObject.new
      
      item = Coarnotify::Core::Notify::NotifyItem.new
      item.id = "https://example.com/item"
      
      object.item = item
      expect(object.item.id).to eq("https://example.com/item")
    end

    it "can set and get triple" do
      object = Coarnotify::Core::Notify::NotifyObject.new
      
      triple = ["https://example.com/object", "https://example.com/relationship", "https://example.com/subject"]
      object.triple = triple
      
      expect(object.triple).to eq(triple)
    end

    it "validates with only id required" do
      object = Coarnotify::Core::Notify::NotifyObject.new
      object.id = "https://example.com/object"
      
      expect(object.validate).to be true
    end
  end

  describe "NotifyActor" do
    it "has default type of Service" do
      actor = Coarnotify::Core::Notify::NotifyActor.new
      expect(actor.type).to eq("Service")
    end

    it "has correct allowed types" do
      expected_types = [
        "Service",
        "Application",
        "Group",
        "Organization",
        "Person"
      ]
      expect(Coarnotify::Core::Notify::NotifyActor.allowed_types).to eq(expected_types)
    end

    it "can set and get name" do
      actor = Coarnotify::Core::Notify::NotifyActor.new
      
      actor.name = "Test Actor"
      expect(actor.name).to eq("Test Actor")
    end

    it "validates type against allowed types" do
      actor = Coarnotify::Core::Notify::NotifyActor.new
      
      actor.type = "Person"
      expect(actor.type).to eq("Person")
      
      expect {
        actor.type = "InvalidType"
      }.to raise_error(ArgumentError, /is not one of the permitted values/)
    end
  end

  describe "NotifyItem" do
    it "can set and get media_type" do
      item = Coarnotify::Core::Notify::NotifyItem.new
      
      item.media_type = "application/pdf"
      expect(item.media_type).to eq("application/pdf")
    end

    it "validates with only id required" do
      item = Coarnotify::Core::Notify::NotifyItem.new
      item.id = "https://example.com/item"
      
      expect(item.validate).to be true
    end
  end

  describe "Pattern-specific models" do
    describe "Accept" do
      it "has correct type constant" do
        expect(Coarnotify::Patterns::Accept.type_constant).to eq("Accept")
      end

      it "ensures type contains Accept" do
        accept = Coarnotify::Patterns::Accept.new
        expect(accept.type).to eq("Accept")
      end

      it "validates inReplyTo matches object.id" do
        accept = Coarnotify::Patterns::Accept.new

        # Set up required properties
        accept.origin = Coarnotify::Core::Notify::NotifyService.new
        accept.origin.id = "https://example.com/origin"

        accept.target = Coarnotify::Core::Notify::NotifyService.new
        accept.target.id = "https://example.com/target"

        accept.object = Coarnotify::Core::Notify::NotifyObject.new
        accept.object.id = "https://example.com/object"

        # For Accept pattern, inReplyTo must match object.id
        accept.in_reply_to = accept.object.id

        expect(accept.validate).to be true

        # Test mismatched inReplyTo
        accept.in_reply_to = "https://example.com/different"
        expect { accept.validate }.to raise_error(Coarnotify::ValidationError)
      end
    end

    describe "RequestReview" do
      it "has correct type constant" do
        expect(Coarnotify::Patterns::RequestReview.type_constant).to eq(["Offer", "coar-notify:ReviewAction"])
      end

      it "ensures type contains both required types" do
        request_review = Coarnotify::Patterns::RequestReview.new
        expect(request_review.type).to eq(["Offer", "coar-notify:ReviewAction"])
      end
    end
  end
end
