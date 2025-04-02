ACTIVITY_STREAMS_NAMESPACE = "https://www.w3.org/ns/activitystreams"
# Namespace for Activity Streams, to be used to construct namespaced properties used in COAR Notify Patterns

class Properties
  ID = ["id", ACTIVITY_STREAMS_NAMESPACE]
  # ``id`` property

  TYPE = ["type", ACTIVITY_STREAMS_NAMESPACE]
  # ``type`` property

  ORIGIN = ["origin", ACTIVITY_STREAMS_NAMESPACE]
  # ``origin`` property

  OBJECT = ["object", ACTIVITY_STREAMS_NAMESPACE]
  # ``object`` property

  TARGET = ["target", ACTIVITY_STREAMS_NAMESPACE]
  # ``target`` property

  ACTOR = ["actor", ACTIVITY_STREAMS_NAMESPACE]
  # ``actor`` property

  IN_REPLY_TO = ["inReplyTo", ACTIVITY_STREAMS_NAMESPACE]
  # ``inReplyTo`` property

  CONTEXT = ["context", ACTIVITY_STREAMS_NAMESPACE]
  # ``context`` property

  SUMMARY = ["summary", ACTIVITY_STREAMS_NAMESPACE]
  # ``summary`` property

  SUBJECT_TRIPLE = ["as:subject", ACTIVITY_STREAMS_NAMESPACE]
  # ``as:subject`` property

  OBJECT_TRIPLE = ["as:object", ACTIVITY_STREAMS_NAMESPACE]
  # ``as:object`` property

  RELATIONSHIP_TRIPLE = ["as:relationship", ACTIVITY_STREAMS_NAMESPACE]
  # ``as:relationship`` property
end

class ActivityStreamsTypes
  # List of all the Activity Streams types COAR Notify may use.
  #
  # Note that COAR Notify also has its own custom types and they are defined in
  # :py:class:`coarnotify.models.notify.NotifyTypes`

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

class ActivityStream
  # A simple wrapper around an ActivityStreams dictionary object
  #
  # Construct it with a Ruby hash that represents an ActivityStreams object, or
  # without to create a fresh, blank object.
  #
  # :param raw: the raw ActivityStreams object, as a hash
  attr_accessor :doc, :context

  def initialize(raw = nil)
    # Construct a new ActivityStream object
    #
    # :param raw: the raw ActivityStreams object, as a hash
    @doc = raw || {}
    @context = []
    if @doc["@context"]
      @context = @doc["@context"]
      @context = [@context] unless @context.is_a?(Array)
      @doc.delete("@context")
    end
  end

  private

  # Register a namespace in the context of the ActivityStream
  def register_namespace(namespace)
    entry = namespace
    if namespace.is_a?(Array)
      url = namespace[1]
      short = namespace[0]
      entry = {short => url}
    end

    @context << entry unless @context.include?(entry)
  end

  # Set an arbitrary property on the object. The property name can be one of:
  #
  # * A simple string with the property name
  # * An array of the property name and the full namespace `["name", "http://example.com/ns"]`
  # * An array containing the property name and another array of the short name and the full namespace `["name", ["as", "http://example.com/ns"]]`
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
  # * An array of the property name and the full namespace `["name", "http://example.com/ns"]`
  # * An array containing the property name and another array of the short name and the full namespace `["name", ["as", "http://example.com/ns"]]`
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
  # :return: a hash representing the ActivityStream object in JSON-LD format
  def to_jsonld
    {
      "@context" => @context,
      **@doc
    }
  end
end