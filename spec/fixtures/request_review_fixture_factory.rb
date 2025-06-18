# frozen_string_literal: true

require_relative 'base_fixture_factory'

module Fixtures
  # Fixture factory for RequestReview pattern
  class RequestReviewFixtureFactory < BaseFixtureFactory
    # Get the source data for RequestReview pattern
    #
    # @param copy [Boolean] whether to return a deep copy or the original
    # @return [Hash] the fixture data
    def self.source(copy: true)
      data = REQUEST_REVIEW_DATA
      copy ? Marshal.load(Marshal.dump(data)) : data
    end

    # Get invalid version of the RequestReview data
    #
    # @return [Hash] the invalid fixture data
    def self.invalid
      source_data = source
      base_invalid(source_data)
      actor_invalid(source_data)
      object_invalid(source_data)
      source_data
    end

    REQUEST_REVIEW_DATA = {
      "@context" => [
        "https://www.w3.org/ns/activitystreams",
        "https://coar-notify.net"
      ],
      "actor" => {
        "id" => "https://orcid.org/0000-0002-1825-0097",
        "name" => "Josiah Carberry",
        "type" => "Person"
      },
      "id" => "urn:uuid:0370c0fb-bb78-4a9b-87f5-bed307a509dd",
      "object" => {
        "id" => "https://research-organisation.org/repository/preprint/201203/421/",
        "ietf:cite-as" => "https://doi.org/10.5555/12345680",
        "ietf:item" => {
          "id" => "https://research-organisation.org/repository/preprint/201203/421/content.pdf",
          "mediaType" => "application/pdf",
          "type" => [
            "Article",
            "sorg:ScholarlyArticle"
          ]
        },
        "type" => [
          "Page",
          "sorg:AboutPage"
        ]
      },
      "origin" => {
        "id" => "https://research-organisation.org/repository",
        "inbox" => "https://research-organisation.org/inbox/",
        "type" => "Service"
      },
      "target" => {
        "id" => "https://review-service.com/system",
        "inbox" => "https://review-service.com/inbox/",
        "type" => "Service"
      },
      "type" => [
        "Offer",
        "coar-notify:ReviewAction"
      ]
    }.freeze
  end
end
