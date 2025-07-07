# frozen_string_literal: true

module Fixtures
  # Base class for all fixture factories
  class BaseFixtureFactory
    # Get the source data for this fixture
    #
    # @param copy [Boolean] whether to return a deep copy or the original
    # @return [Hash] the fixture data
    def self.source(copy: true)
      raise NotImplementedError, "Subclasses must implement source method"
    end

    # Get invalid version of the source data
    #
    # @return [Hash] the invalid fixture data
    def self.invalid
      source_data = source
      base_invalid(source_data)
      source_data
    end

    # Get expected value from a path in the source data
    #
    # @param path [String] dot-separated path to the value
    # @return [Object] the value at the path
    def self.expected_value(path)
      source_data = source(copy: false)
      value_from_hash(path, source_data)
    end

    private

    # Make base properties invalid for testing validation
    #
    # @param source [Hash] the source data to modify
    # @return [Hash] the modified source data
    def self.base_invalid(source)
      source["id"] = "not a uri"
      source["inReplyTo"] = "not a uri"
      source["origin"]["id"] = "urn:uuid:4fb3af44-d4f8-4226-9475-2d09c2d8d9e0"
      source["origin"]["inbox"] = "not a uri"
      source["origin"]["type"] = "NotAValidType"
      source["target"]["id"] = "urn:uuid:4fb3af44-d4f8-4226-9475-2d09c2d8d9e0"
      source["target"]["inbox"] = "not a uri"
      source["target"]["type"] = "NotAValidType"
      source["type"] = "NotAValidType"
      source
    end

    # Make actor properties invalid for testing validation
    #
    # @param source [Hash] the source data to modify
    # @return [Hash] the modified source data
    def self.actor_invalid(source)
      source["actor"]["id"] = "not a uri"
      source["actor"]["type"] = "NotAValidType"
      source
    end

    # Make object properties invalid for testing validation
    #
    # @param source [Hash] the source data to modify
    # @return [Hash] the modified source data
    def self.object_invalid(source)
      source["object"]["id"] = "not a uri"
      source["object"]["ietf:cite-as"] = "urn:uuid:4fb3af44-d4f8-4226-9475-2d09c2d8d9e0"
      source
    end

    # Make context properties invalid for testing validation
    #
    # @param source [Hash] the source data to modify
    # @return [Hash] the modified source data
    def self.context_invalid(source)
      source["context"]["id"] = "not a uri"
      source["context"]["type"] = "NotAValidType"
      source["context"]["ietf:cite-as"] = "urn:uuid:4fb3af44-d4f8-4226-9475-2d09c2d8d9e0"
      source
    end

    # Get value from hash using dot-separated path
    #
    # @param path [String] dot-separated path
    # @param hash [Hash] the hash to traverse
    # @return [Object] the value at the path
    def self.value_from_hash(path, hash)
      bits = path.split(".")
      node = hash
      bits.each do |bit|
        node = node[bit]
      end
      node
    end
  end
end
