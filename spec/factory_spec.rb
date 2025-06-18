# frozen_string_literal: true

require 'spec_helper'
require_relative 'fixtures/accept_fixture_factory'
require_relative 'fixtures/request_review_fixture_factory'

RSpec.describe Coarnotify::Factory::COARNotifyFactory do
  describe ".get_by_types" do
    it "returns Accept class for Accept type" do
      result = described_class.get_by_types("Accept")
      expect(result).to eq(Coarnotify::Patterns::Accept)
    end

    it "returns RequestReview class for RequestReview types" do
      result = described_class.get_by_types(["Offer", "coar-notify:ReviewAction"])
      expect(result).to eq(Coarnotify::Patterns::RequestReview)
    end

    it "returns AnnounceEndorsement class for AnnounceEndorsement types" do
      result = described_class.get_by_types(["Announce", "coar-notify:EndorsementAction"])
      expect(result).to eq(Coarnotify::Patterns::AnnounceEndorsement)
    end

    it "returns AnnounceRelationship class for AnnounceRelationship types" do
      result = described_class.get_by_types(["Announce", "coar-notify:RelationshipAction"])
      expect(result).to eq(Coarnotify::Patterns::AnnounceRelationship)
    end

    it "returns AnnounceReview class for AnnounceReview types" do
      result = described_class.get_by_types(["Announce", "coar-notify:ReviewAction"])
      expect(result).to eq(Coarnotify::Patterns::AnnounceReview)
    end

    it "returns AnnounceServiceResult class for AnnounceServiceResult types" do
      result = described_class.get_by_types(["Announce", "coar-notify:IngestAction"])
      expect(result).to eq(Coarnotify::Patterns::AnnounceServiceResult)
    end

    it "returns Reject class for Reject type" do
      result = described_class.get_by_types("Reject")
      expect(result).to eq(Coarnotify::Patterns::Reject)
    end

    it "returns RequestEndorsement class for RequestEndorsement types" do
      result = described_class.get_by_types(["Offer", "coar-notify:EndorsementAction"])
      expect(result).to eq(Coarnotify::Patterns::RequestEndorsement)
    end

    it "returns TentativelyAccept class for TentativelyAccept type" do
      result = described_class.get_by_types("TentativeAccept")
      expect(result).to eq(Coarnotify::Patterns::TentativelyAccept)
    end

    it "returns TentativelyReject class for TentativelyReject type" do
      result = described_class.get_by_types("TentativeReject")
      expect(result).to eq(Coarnotify::Patterns::TentativelyReject)
    end

    it "returns UnprocessableNotification class for UnprocessableNotification type" do
      result = described_class.get_by_types("coar-notify:UnprocessableNotification")
      expect(result).to eq(Coarnotify::Patterns::UnprocessableNotification)
    end

    it "returns UndoOffer class for UndoOffer type" do
      result = described_class.get_by_types("Undo")
      expect(result).to eq(Coarnotify::Patterns::UndoOffer)
    end
  end

  describe ".get_by_object" do
    it "creates Accept instance from Accept fixture data" do
      source = Fixtures::AcceptFixtureFactory.source
      result = described_class.get_by_object(source)
      
      expect(result).to be_a(Coarnotify::Patterns::Accept)
      expect(result.id).to eq(source["id"])
    end

    it "creates RequestReview instance from RequestReview fixture data" do
      source = Fixtures::RequestReviewFixtureFactory.source
      result = described_class.get_by_object(source)
      
      expect(result).to be_a(Coarnotify::Patterns::RequestReview)
      expect(result.id).to eq(source["id"])
    end

    it "raises error when no type found in object" do
      data = { "id" => "test" }
      expect {
        described_class.get_by_object(data)
      }.to raise_error(Coarnotify::NotifyException, "No type found in object")
    end

    it "raises error when no matching pattern found" do
      data = { "type" => "UnknownType", "id" => "test" }
      expect {
        described_class.get_by_object(data)
      }.to raise_error(Coarnotify::NotifyException, /No matching pattern found for types/)
    end
  end

  describe ".register" do
    it "registers a new pattern class" do
      # Create a test pattern class
      test_pattern_class = Class.new(Coarnotify::Core::Notify::NotifyPattern) do
        def self.type_constant
          "Accept"
        end
      end

      # Register it
      described_class.register(test_pattern_class)

      # Verify it's now returned for Accept type
      result = described_class.get_by_types("Accept")
      expect(result).to eq(test_pattern_class)

      # Clean up by re-registering the original Accept class
      described_class.register(Coarnotify::Patterns::Accept)
    end
  end
end
