# frozen_string_literal: true

require 'json'

module Coarnotify
  module Core
    # This module contains everything COAR Notify needs to know about ActivityStreams 2.0
    # https://www.w3.org/TR/activitystreams-core/
    #
    # It provides knowledge of the essential AS properties and types, and a class to wrap
    # ActivityStreams objects and provide a simple interface to work with them.
    #
    # **NOTE** this is not a complete implementation of AS 2.0, it is **only** what is required
    # to work with COAR Notify patterns.
    module ActivityStreams2
      # Namespace for Activity Streams, to be used to construct namespaced properties used in COAR Notify Patterns
      ACTIVITY_STREAMS_NAMESPACE = "https://www.w3.org/ns/activitystreams"

      # ActivityStreams 2.0 properties used in COAR Notify Patterns
      #
      # These are provided as arrays, where the first element is the property name, and the second element is the namespace.
      #
      # These are suitable to be used as property names in all the property getters/setters in the notify pattern objects
      # and in the validation configuration.
      module Properties
        # id property
        ID = ["id", ACTIVITY_STREAMS_NAMESPACE].freeze

        # type property
        TYPE = ["type", ACTIVITY_STREAMS_NAMESPACE].freeze

        # origin property
        ORIGIN = ["origin", ACTIVITY_STREAMS_NAMESPACE].freeze

        # object property
        OBJECT = ["object", ACTIVITY_STREAMS_NAMESPACE].freeze

        # target property
        TARGET = ["target", ACTIVITY_STREAMS_NAMESPACE].freeze

        # actor property
        ACTOR = ["actor", ACTIVITY_STREAMS_NAMESPACE].freeze

        # inReplyTo property
        IN_REPLY_TO = ["inReplyTo", ACTIVITY_STREAMS_NAMESPACE].freeze

        # context property
        CONTEXT = ["context", ACTIVITY_STREAMS_NAMESPACE].freeze

        # summary property
        SUMMARY = ["summary", ACTIVITY_STREAMS_NAMESPACE].freeze

        # as:subject property
        SUBJECT_TRIPLE = ["as:subject", ACTIVITY_STREAMS_NAMESPACE].freeze

        # as:object property
        OBJECT_TRIPLE = ["as:object", ACTIVITY_STREAMS_NAMESPACE].freeze

        # as:relationship property
        RELATIONSHIP_TRIPLE = ["as:relationship", ACTIVITY_STREAMS_NAMESPACE].freeze
      end

      # List of all the Activity Streams types COAR Notify may use.
      #
      # Note that COAR Notify also has its own custom types and they are defined in
      # Coarnotify::Core::Notify::NotifyTypes
      module ActivityStreamsTypes
        # Activities
        ACCEPT = "Accept"
        ANNOUNCE = "Announce"
        REJECT = "Reject"
        OFFER = "Offer"
        TENTATIVE_ACCEPT = "TentativeAccept"
        TENTATIVE_REJECT = "TentativeReject"
        FLAG = "Flag"
        UNDO = "Undo"

        # Objects
        ACTIVITY = "Activity"
        APPLICATION = "Application"
        ARTICLE = "Article"
        AUDIO = "Audio"
        COLLECTION = "Collection"
        COLLECTION_PAGE = "CollectionPage"
        RELATIONSHIP = "Relationship"
        DOCUMENT = "Document"
        EVENT = "Event"
        GROUP = "Group"
        IMAGE = "Image"
        INTRANSITIVE_ACTIVITY = "IntransitiveActivity"
        NOTE = "Note"
        OBJECT = "Object"
        ORDERED_COLLECTION = "OrderedCollection"
        ORDERED_COLLECTION_PAGE = "OrderedCollectionPage"
        ORGANIZATION = "Organization"
        PAGE = "Page"
        PERSON = "Person"
        PLACE = "Place"
        PROFILE = "Profile"
        QUESTION = "Question"
        SERVICE = "Service"
        TOMBSTONE = "Tombstone"
        VIDEO = "Video"
      end

      # The sub-list of ActivityStreams types that are also objects in AS 2.0
      ACTIVITY_STREAMS_OBJECTS = [
        ActivityStreamsTypes::ACTIVITY,
        ActivityStreamsTypes::APPLICATION,
        ActivityStreamsTypes::ARTICLE,
        ActivityStreamsTypes::AUDIO,
        ActivityStreamsTypes::COLLECTION,
        ActivityStreamsTypes::COLLECTION_PAGE,
        ActivityStreamsTypes::RELATIONSHIP,
        ActivityStreamsTypes::DOCUMENT,
        ActivityStreamsTypes::EVENT,
        ActivityStreamsTypes::GROUP,
        ActivityStreamsTypes::IMAGE,
        ActivityStreamsTypes::INTRANSITIVE_ACTIVITY,
        ActivityStreamsTypes::NOTE,
        ActivityStreamsTypes::OBJECT,
        ActivityStreamsTypes::ORDERED_COLLECTION,
        ActivityStreamsTypes::ORDERED_COLLECTION_PAGE,
        ActivityStreamsTypes::ORGANIZATION,
        ActivityStreamsTypes::PAGE,
        ActivityStreamsTypes::PERSON,
        ActivityStreamsTypes::PLACE,
        ActivityStreamsTypes::PROFILE,
        ActivityStreamsTypes::QUESTION,
        ActivityStreamsTypes::SERVICE,
        ActivityStreamsTypes::TOMBSTONE,
        ActivityStreamsTypes::VIDEO
      ].freeze

      # A simple wrapper around an ActivityStreams hash object
      #
      # Construct it with a ruby hash that represents an ActivityStreams object, or
      # without to create a fresh, blank object.
      class ActivityStream
        attr_reader :doc, :context

        # Construct a new ActivityStream object
        #
        # @param raw [Hash] the raw ActivityStreams object, as a hash
        def initialize(raw = nil)
          @doc = raw || {}
          @context = []
          if @doc.key?("@context")
            @context = @doc["@context"]
            @context = [@context] unless @context.is_a?(Array)
            @doc.delete("@context")
          end
        end

        # Set the document hash
        #
        # @param doc [Hash] the document hash to set
        def doc=(doc)
          @doc = doc
        end

        # Set the context
        #
        # @param context [Array, String] the context to set
        def context=(context)
          @context = context
        end

        # Register a namespace in the context of the ActivityStream
        #
        # @param namespace [String, Array] the namespace to register
        def register_namespace(namespace)
          entry = namespace
          if namespace.is_a?(Array)
            url = namespace[1]
            short = namespace[0]
            entry = { short => url }
          end

          @context << entry unless @context.include?(entry)
        end

        # Set an arbitrary property on the object. The property name can be one of:
        #
        # * A simple string with the property name
        # * An array of the property name and the full namespace ["name", "http://example.com/ns"]
        # * An array containing the property name and another array of the short name and the full namespace ["name", ["as", "http://example.com/ns"]]
        #
        # @param property [String, Array] the property name
        # @param value [Object] the value to set
        def set_property(property, value)
          prop_name = property
          namespace = nil
          if property.is_a?(Array)
            prop_name = property[0]
            namespace = property[1]
          end

          @doc[prop_name] = value
          register_namespace(namespace) if namespace
        end

        # Get an arbitrary property on the object. The property name can be one of:
        #
        # * A simple string with the property name
        # * An array of the property name and the full namespace ["name", "http://example.com/ns"]
        # * An array containing the property name and another array of the short name and the full namespace ["name", ["as", "http://example.com/ns"]]
        #
        # @param property [String, Array] the property name
        # @return [Object] the value of the property, or nil if it does not exist
        def get_property(property)
          prop_name = property
          namespace = nil
          if property.is_a?(Array)
            prop_name = property[0]
            namespace = property[1]
          end

          @doc[prop_name]
        end

        # Get the activity stream as a JSON-LD object
        #
        # @return [Hash] the JSON-LD representation
        def to_jsonld
          {
            "@context" => @context,
            **@doc
          }
        end
      end
    end
  end
end
