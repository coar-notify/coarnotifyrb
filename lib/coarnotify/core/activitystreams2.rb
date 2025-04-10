# This module contains ActivityStreams 2.0 implementation for COAR Notify
# https://www.w3.org/TR/activitystreams-core/

# It provides knowledge of the essential AS properties and types, and a class to wrap
# ActivityStreams objects and provide a simple interface to work with them.

# **NOTE** this is not a complete implementation of AS 2.0, it is **only** what is required
# to work with COAR Notify patterns.

module COARNotify
  ACTIVITY_STREAMS_NAMESPACE = "https://www.w3.org/ns/activitystreams".freeze

  # Namespace for Actvitity Streams, to be used to construct namespaced properties used in COAR Notify Patterns
  
  module Properties
    ID = ["id", ACTIVITY_STREAMS_NAMESPACE].freeze
    TYPE = ["type", ACTIVITY_STREAMS_NAMESPACE].freeze
    ORIGIN = ["origin", ACTIVITY_STREAMS_NAMESPACE].freeze
    OBJECT = ["object", ACTIVITY_STREAMS_NAMESPACE].freeze
    TARGET = ["target", ACTIVITY_STREAMS_NAMESPACE].freeze
    ACTOR = ["actor", ACTIVITY_STREAMS_NAMESPACE].freeze
    IN_REPLY_TO = ["inReplyTo", ACTIVITY_STREAMS_NAMESPACE].freeze
    CONTEXT = ["context", ACTIVITY_STREAMS_NAMESPACE].freeze
    SUMMARY = ["summary", ACTIVITY_STREAMS_NAMESPACE].freeze
    SUBJECT_TRIPLE = ["as:subject", ACTIVITY_STREAMS_NAMESPACE].freeze
    OBJECT_TRIPLE = ["as:object", ACTIVITY_STREAMS_NAMESPACE].freeze
    RELATIONSHIP_TRIPLE = ["as:relationship", ACTIVITY_STREAMS_NAMESPACE].freeze
  end

  module ActivityStreamsTypes
    #  List of all the Activity Streams types COAR Notify may use.
    # Note that COAR Notify also has its own custom types and they are defined in

    # Activities
    ACCEPT = "Accept".freeze
    ANNOUNCE = "Announce".freeze
    REJECT = "Reject".freeze
    OFFER = "Offer".freeze
    TENTATIVE_ACCEPT = "TentativeAccept".freeze
    TENTATIVE_REJECT = "TentativeReject".freeze
    FLAG = "Flag".freeze
    UNDO = "Undo".freeze

    # Objects
    ACTIVITY = "Activity".freeze
    APPLICATION = "Application".freeze
    ARTICLE = "Article".freeze
    AUDIO = "Audio".freeze
    COLLECTION = "Collection".freeze
    COLLECTION_PAGE = "CollectionPage".freeze
    RELATIONSHIP = "Relationship".freeze
    DOCUMENT = "Document".freeze
    EVENT = "Event".freeze
    GROUP = "Group".freeze
    IMAGE = "Image".freeze
    INTRANSITIVE_ACTIVITY = "IntransitiveActivity".freeze
    NOTE = "Note".freeze
    OBJECT = "Object".freeze
    ORDERED_COLLECTION = "OrderedCollection".freeze
    ORDERED_COLLECTION_PAGE = "OrderedCollectionPage".freeze
    ORGANIZATION = "Organization".freeze
    PAGE = "Page".freeze
    PERSON = "Person".freeze
    PLACE = "Place".freeze
    PROFILE = "Profile".freeze
    QUESTION = "Question".freeze
    SERVICE = "Service".freeze
    TOMBSTONE = "Tombstone".freeze
    VIDEO = "Video".freeze
  end

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

  # The sub-list of ActivityStreams types that are also objects in AS 2.0

  class ActivityStream

    # A simple wrapper around an ActivityStreams dictionary object

    # Construct it with a python dictionary that represents an ActivityStreams object, or
    # without to create a fresh, blank object.

    # :param raw: the raw ActivityStreams object,

    attr_accessor :doc, :context

    def initialize(raw = nil)
      # Construct a new ActivityStream object

      # :param raw: the raw ActivityStreams object
      @doc = raw || {}
      @context = []
      if @doc.key?("@context")
        @context = Array(@doc["@context"])
        @doc.delete("@context")
      end
    end

    def set_property(property, value)

      # Set an arbitrary property on the object.  The property name can be one of:

      # * A simple string with the property name
      # * A tuple of the property name and the full namespace ``("name", "http://example.com/ns")``
      # * A tuple containing the property name and another tuple of the short name and the full namespace ``("name", ("as", "http://example.com/ns"))``

      # :param property: the property name
      # :param value: the value to set

      prop_name, namespace = if property.is_a?(Array)
                              [property[0], property[1]]
                            else
                              [property, nil]
                            end

      @doc[prop_name] = value
      register_namespace(namespace) if namespace
    end

    def get_property(property)

      # Get an arbitrary property on the object.  The property name can be one of:

      # * A simple string with the property name
      # * A tuple of the property name and the full namespace ``("name", "http://example.com/ns")``
      # * A tuple containing the property name and another tuple of the short name and the full namespace ``("name", ("as", "http://example.com/ns"))``

      # :param property:   the property name
      # :return: the value of the property, or None if it does not exist

      prop_name = property.is_a?(Array) ? property[0] : property
      @doc[prop_name]
    end

    def to_jsonld

      # Get the activity stream as a JSON-LD object

      # :return:

      { "@context" => @context }.merge(@doc)
    end

    private

    def register_namespace(namespace)
      # Register a namespace in the context of the ActivityStream
      entry = if namespace.is_a?(Array)
                { namespace[0] => namespace[1] }
              else
                namespace
              end

      @context << entry unless @context.include?(entry)
    end
  end
end