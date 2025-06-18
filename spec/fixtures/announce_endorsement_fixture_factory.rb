# frozen_string_literal: true

require_relative 'base_fixture_factory'

module Fixtures
  # Fixture factory for AnnounceEndorsement pattern
  class AnnounceEndorsementFixtureFactory < BaseFixtureFactory
    def self.source(copy: true)
      data = ANNOUNCE_ENDORSEMENT_DATA
      copy ? Marshal.load(Marshal.dump(data)) : data
    end

    def self.invalid
      source_data = source
      base_invalid(source_data)
      actor_invalid(source_data)
      object_invalid(source_data)
      context_invalid(source_data)
      source_data
    end

    ANNOUNCE_ENDORSEMENT_DATA = {
      "@context" => [
        "https://www.w3.org/ns/activitystreams",
        "https://coar-notify.net"
      ],
      "actor" => {
        "id" => "https://orcid.org/0000-0002-1825-0097",
        "name" => "Josiah Carberry",
        "type" => "Person"
      },
      "context" => {
        "id" => "https://research-organisation.org/repository/preprint/201203/421/",
        "ietf:cite-as" => "https://doi.org/10.5555/12345680",
        "type" => "sorg:AboutPage"
      },
      "id" => "urn:uuid:94ecae35-dcfd-4182-8550-22c7164fe23f",
      "object" => {
        "id" => "https://overlay-journal.com/reviews/000001/",
        "type" => "sorg:Review"
      },
      "origin" => {
        "id" => "https://overlay-journal.com/system",
        "inbox" => "https://overlay-journal.com/inbox/",
        "type" => "Service"
      },
      "target" => {
        "id" => "https://research-organisation.org/repository",
        "inbox" => "https://research-organisation.org/inbox/",
        "type" => "Service"
      },
      "type" => [
        "Announce",
        "coar-notify:EndorsementAction"
      ]
    }.freeze
  end
end
