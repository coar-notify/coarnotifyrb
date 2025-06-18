# frozen_string_literal: true

require 'securerandom'
require 'set'
require_relative 'activity_streams2'
require_relative '../validate'
require_relative '../exceptions'

module Coarnotify
  module Core
    # This module is home to all the core model objects from which the notify patterns extend
    module Notify
      # Namespace for COAR Notify, to be used to construct namespaced properties used in COAR Notify Patterns
      NOTIFY_NAMESPACE = "https://coar-notify.net"

      # COAR Notify properties used in COAR Notify Patterns
      #
      # Most of these are provided as arrays, where the first element is the property name, and the second element is the namespace.
      # Some are provided as plain strings without namespaces
      #
      # These are suitable to be used as property names in all the property getters/setters in the notify pattern objects
      # and in the validation configuration.
      module NotifyProperties
        # inbox property
        INBOX = ["inbox", NOTIFY_NAMESPACE].freeze

        # ietf:cite-as property
        CITE_AS = ["ietf:cite-as", NOTIFY_NAMESPACE].freeze

        # ietf:item property
        ITEM = ["ietf:item", NOTIFY_NAMESPACE].freeze

        # name property
        NAME = "name"

        # mediaType property
        MEDIA_TYPE = "mediaType"
      end

      # List of all the COAR Notify types patterns may use.
      #
      # These are in addition to the base Activity Streams types, which are in ActivityStreams2::ActivityStreamsTypes
      module NotifyTypes
        ENDORSEMENT_ACTION = "coar-notify:EndorsementAction"
        INGEST_ACTION = "coar-notify:IngestAction"
        RELATIONSHIP_ACTION = "coar-notify:RelationshipAction"
        REVIEW_ACTION = "coar-notify:ReviewAction"
        UNPROCESSABLE_NOTIFICATION = "coar-notify:UnprocessableNotification"

        ABOUT_PAGE = "sorg:AboutPage"
      end

      # Validation rules for notify patterns
      VALIDATION_RULES = {
        ActivityStreams2::Properties::ID => {
          "default" => proc { |obj, uri| Validate.absolute_uri(obj, uri) },
          "context" => {
            ActivityStreams2::Properties::CONTEXT => {
              "default" => proc { |obj, url| Validate.url(obj, url) }
            },
            ActivityStreams2::Properties::ORIGIN => {
              "default" => proc { |obj, url| Validate.url(obj, url) }
            },
            ActivityStreams2::Properties::TARGET => {
              "default" => proc { |obj, url| Validate.url(obj, url) }
            },
            NotifyProperties::ITEM => {
              "default" => proc { |obj, url| Validate.url(obj, url) }
            }
          }
        },
        ActivityStreams2::Properties::TYPE => {
          "default" => proc { |obj, value| Validate.type_checker(obj, value) },
          "context" => {
            ActivityStreams2::Properties::ACTOR => {
              "default" => Validate.one_of([
                ActivityStreams2::ActivityStreamsTypes::SERVICE,
                ActivityStreams2::ActivityStreamsTypes::APPLICATION,
                ActivityStreams2::ActivityStreamsTypes::GROUP,
                ActivityStreams2::ActivityStreamsTypes::ORGANIZATION,
                ActivityStreams2::ActivityStreamsTypes::PERSON
              ])
            },
            ActivityStreams2::Properties::OBJECT => {
              "default" => Validate.at_least_one_of(ActivityStreams2::ACTIVITY_STREAMS_OBJECTS)
            },
            ActivityStreams2::Properties::CONTEXT => {
              "default" => Validate.at_least_one_of(ActivityStreams2::ACTIVITY_STREAMS_OBJECTS)
            },
            NotifyProperties::ITEM => {
              "default" => Validate.at_least_one_of(ActivityStreams2::ACTIVITY_STREAMS_OBJECTS + [NotifyTypes::ABOUT_PAGE])
            }
          }
        },
        NotifyProperties::CITE_AS => {
          "default" => proc { |obj, url| Validate.url(obj, url) }
        },
        NotifyProperties::INBOX => {
          "default" => proc { |obj, url| Validate.url(obj, url) }
        },
        ActivityStreams2::Properties::IN_REPLY_TO => {
          "default" => proc { |obj, uri| Validate.absolute_uri(obj, uri) }
        },
        ActivityStreams2::Properties::SUBJECT_TRIPLE => {
          "default" => proc { |obj, uri| Validate.absolute_uri(obj, uri) }
        },
        ActivityStreams2::Properties::OBJECT_TRIPLE => {
          "default" => proc { |obj, uri| Validate.absolute_uri(obj, uri) }
        },
        ActivityStreams2::Properties::RELATIONSHIP_TRIPLE => {
          "default" => proc { |obj, uri| Validate.absolute_uri(obj, uri) }
        }
      }.freeze

      # Default Validator object for all pattern types
      VALIDATORS = Validate::Validator.new(VALIDATION_RULES)

      # Base class from which all Notify objects extend.
      #
      # There are two kinds of Notify objects:
      #
      # 1. Patterns, which are the notifications themselves
      # 2. Pattern Parts, which are nested elements in the Patterns, such as objects, contexts, actors, etc
      #
      # This class forms the basis for both of those types, and provides essential services,
      # such as construction, accessors and validation, as well as supporting the essential
      # properties "id" and "type"
      class NotifyBase
        attr_reader :validate_stream_on_construct, :validate_properties, :validators, :properties_by_reference

        # Base constructor that all subclasses should call
        #
        # @param stream [ActivityStreams2::ActivityStream, Hash] The activity stream object, or a hash from which one can be created
        # @param validate_stream_on_construct [Boolean] should the incoming stream be validated at construction-time
        # @param validate_properties [Boolean] should individual properties be validated as they are set
        # @param validators [Validate::Validator] the validator object for this class and all nested elements
        # @param validation_context [String, Array] the context in which this object is being validated
        # @param properties_by_reference [Boolean] should properties be get and set by reference (the default) or by value
        def initialize(stream: nil, validate_stream_on_construct: true, validate_properties: true,
                       validators: nil, validation_context: nil, properties_by_reference: true)
          @validate_stream_on_construct = validate_stream_on_construct
          @validate_properties = validate_properties
          @validators = validators || VALIDATORS
          @validation_context = validation_context
          @properties_by_reference = properties_by_reference
          validate_now = false

          if stream.nil?
            @stream = ActivityStreams2::ActivityStream.new
          elsif stream.is_a?(Hash)
            validate_now = validate_stream_on_construct
            @stream = ActivityStreams2::ActivityStream.new(stream)
          else
            validate_now = validate_stream_on_construct
            @stream = stream
          end

          if @stream.get_property(ActivityStreams2::Properties::ID).nil?
            @stream.set_property(ActivityStreams2::Properties::ID, "urn:uuid:#{SecureRandom.hex}")
          end

          validate if validate_now
        end

        # The underlying ActivityStream object, excluding the JSON-LD @context
        #
        # @return [Hash] the document hash
        def doc
          @stream.doc
        end

        # The id of the object
        #
        # @return [String] the id
        def id
          get_property(ActivityStreams2::Properties::ID)
        end

        # Set the id of the object
        #
        # @param value [String] the id to set
        def id=(value)
          set_property(ActivityStreams2::Properties::ID, value)
        end

        # The type of the object
        #
        # @return [String, Array<String>] the type
        def type
          get_property(ActivityStreams2::Properties::TYPE)
        end

        # Set the type of the object
        #
        # @param types [String, Array<String>] the type(s) to set
        def type=(types)
          set_property(ActivityStreams2::Properties::TYPE, types)
        end

        # Generic property getter. It is strongly recommended that all accessors proxy for this method
        # as this enforces by-reference/by-value accessing, and mediates directly with the underlying
        # activity stream object.
        #
        # @param prop_name [String, Array] The property to retrieve
        # @param by_reference [Boolean] Whether to retrieve by_reference or by_value
        # @return [Object] the property value
        def get_property(prop_name, by_reference: nil)
          by_reference = @properties_by_reference if by_reference.nil?
          val = @stream.get_property(prop_name)
          if by_reference
            val
          else
            val.dup rescue val  # Deep copy where possible
          end
        end

        # Generic property setter. It is strongly recommended that all accessors proxy for this method
        # as this enforces by-reference/by-value accessing, and mediates directly with the underlying
        # activity stream object.
        #
        # @param prop_name [String, Array] The property to set
        # @param value [Object] The value to set
        # @param by_reference [Boolean] Whether to set by_reference or by_value
        def set_property(prop_name, value, by_reference: nil)
          by_reference = @properties_by_reference if by_reference.nil?
          validate_property(prop_name, value)
          value = value.dup rescue value unless by_reference  # Deep copy where possible
          @stream.set_property(prop_name, value)
        end

        # Validate the object. This provides the basic validation on id and type.
        # Subclasses should override this method with their own validation, and call this method via super first to ensure
        # the basic properties are validated.
        #
        # @return [Boolean] true or raise a ValidationError if there are errors
        def validate
          ve = ValidationError.new

          required_and_validate(ve, ActivityStreams2::Properties::ID, id)
          required_and_validate(ve, ActivityStreams2::Properties::TYPE, type)

          raise ve if ve.has_errors?
          true
        end

        # Validate a single property. This is used internally by set_property.
        #
        # If the object has validate_properties set to false then that behaviour may be overridden by setting force_validate to true
        #
        # The validator applied to the property will be determined according to the validators property of the object
        # and the validation_context of the object.
        #
        # @param prop_name [String, Array] The property to validate
        # @param value [Object] the value to validate
        # @param force_validate [Boolean] whether to validate anyway, even if property validation is turned off at the object level
        # @param raise_error [Boolean] raise an exception on validation failure, or return a tuple with the result
        # @return [Array] A tuple of whether validation was successful, and the error message if it was not
        def validate_property(prop_name, value, force_validate: false, raise_error: true)
          return [true, ""] if value.nil?
          if @validate_properties || force_validate
            validator = @validators.get(prop_name, @validation_context)
            if validator
              begin
                validator.call(self, value)
              rescue ArgumentError => ve
                if raise_error
                  raise ve
                else
                  return [false, ve.message]
                end
              end
            end
          end
          [true, ""]
        end

        # Force validate the property and if an error is found, add it to the validation error
        #
        # @param ve [ValidationError] the validation error to add to
        # @param prop_name [String, Array] the property name
        # @param value [Object] the value to validate
        def register_property_validation_error(ve, prop_name, value)
          success, msg = validate_property(prop_name, value, force_validate: true, raise_error: false)
          ve.add_error(prop_name, msg) unless success
        end

        # Add a required error to the validation error if the value is nil
        #
        # @param ve [ValidationError] The validation error to which to add the message
        # @param prop_name [String, Array] The property to check
        # @param value [Object] The value
        def required(ve, prop_name, value)
          if value.nil?
            pn = prop_name.is_a?(Array) ? prop_name[0] : prop_name
            ve.add_error(prop_name, Validate::REQUIRED_MESSAGE % pn)
          end
        end

        # Add a required error to the validation error if the value is nil, and then validate the value if not.
        #
        # Any error messages are added to the ValidationError object
        #
        # @param ve [ValidationError] the validation error to which to add the message
        # @param prop_name [String, Array] The property to check
        # @param value [Object] the value to check
        def required_and_validate(ve, prop_name, value)
          if value.nil?
            pn = prop_name.is_a?(Array) ? prop_name[0] : prop_name
            ve.add_error(prop_name, Validate::REQUIRED_MESSAGE % pn)
          else
            if value.is_a?(NotifyBase)
              begin
                value.validate
              rescue ValidationError => subve
                ve.add_nested_errors(prop_name, subve)
              end
            else
              register_property_validation_error(ve, prop_name, value)
            end
          end
        end

        # Validate the value if it is not nil, but do not raise a validation error if it is nil
        #
        # @param ve [ValidationError] the validation error to add to
        # @param prop_name [String, Array] the property name
        # @param value [Object] the value to validate
        def optional_and_validate(ve, prop_name, value)
          if value
            if value.is_a?(NotifyBase)
              begin
                value.validate
              rescue ValidationError => subve
                ve.add_nested_errors(prop_name, subve)
              end
            else
              register_property_validation_error(ve, prop_name, value)
            end
          end
        end

        # Get the notification pattern as JSON-LD
        #
        # @return [Hash] JSON-LD representation of the pattern
        def to_jsonld
          @stream.to_jsonld
        end
      end

      # Base class for all notification patterns
      class NotifyPattern < NotifyBase
        # The type of the pattern. This should be overridden by subclasses, otherwise defaults to Object
        def self.type_constant
          ActivityStreams2::ActivityStreamsTypes::OBJECT
        end

        # Constructor for the NotifyPattern
        #
        # This constructor will ensure that the pattern has its mandated type in the type property
        #
        # @param stream [ActivityStreams2::ActivityStream, Hash] The activity stream object, or a hash from which one can be created
        # @param validate_stream_on_construct [Boolean] should the incoming stream be validated at construction-time
        # @param validate_properties [Boolean] should individual properties be validated as they are set
        # @param validators [Validate::Validator] the validator object for this class and all nested elements
        # @param validation_context [String, Array] the context in which this object is being validated
        # @param properties_by_reference [Boolean] should properties be get and set by reference (the default) or by value
        def initialize(stream: nil, validate_stream_on_construct: true, validate_properties: true,
                       validators: nil, validation_context: nil, properties_by_reference: true)
          super(stream: stream, validate_stream_on_construct: validate_stream_on_construct,
                validate_properties: validate_properties, validators: validators,
                validation_context: validation_context, properties_by_reference: properties_by_reference)
          ensure_type_contains(self.class.type_constant)
        end

        # Ensure that the type field contains the given types
        #
        # @param types [String, Array<String>] the types to ensure are present
        def ensure_type_contains(types)
          existing = @stream.get_property(ActivityStreams2::Properties::TYPE)
          if existing.nil?
            set_property(ActivityStreams2::Properties::TYPE, types)
          else
            existing = [existing] unless existing.is_a?(Array)
            types = [types] unless types.is_a?(Array)
            types.each do |t|
              existing << t unless existing.include?(t)
            end
            existing = existing.length == 1 ? existing[0] : existing
            set_property(ActivityStreams2::Properties::TYPE, existing)
          end
        end

        # Get the origin property of the notification
        #
        # @return [NotifyService, nil] the origin service
        def origin
          o = get_property(ActivityStreams2::Properties::ORIGIN)
          if o
            NotifyService.new(stream: o, validate_stream_on_construct: false,
                              validate_properties: @validate_properties, validators: @validators,
                              validation_context: ActivityStreams2::Properties::ORIGIN,
                              properties_by_reference: @properties_by_reference)
          end
        end

        # Set the origin property of the notification
        #
        # @param value [NotifyService] the origin service to set
        def origin=(value)
          set_property(ActivityStreams2::Properties::ORIGIN, value.doc)
        end

        # Get the target property of the notification
        #
        # @return [NotifyService, nil] the target service
        def target
          t = get_property(ActivityStreams2::Properties::TARGET)
          if t
            NotifyService.new(stream: t, validate_stream_on_construct: false,
                              validate_properties: @validate_properties, validators: @validators,
                              validation_context: ActivityStreams2::Properties::TARGET,
                              properties_by_reference: @properties_by_reference)
          end
        end

        # Set the target property of the notification
        #
        # @param value [NotifyService] the target service to set
        def target=(value)
          set_property(ActivityStreams2::Properties::TARGET, value.doc)
        end

        # Get the object property of the notification
        #
        # @return [NotifyObject, nil] the object
        def object
          o = get_property(ActivityStreams2::Properties::OBJECT)
          if o
            NotifyObject.new(stream: o, validate_stream_on_construct: false,
                             validate_properties: @validate_properties, validators: @validators,
                             validation_context: ActivityStreams2::Properties::OBJECT,
                             properties_by_reference: @properties_by_reference)
          end
        end

        # Set the object property of the notification
        #
        # @param value [NotifyObject] the object to set
        def object=(value)
          set_property(ActivityStreams2::Properties::OBJECT, value.doc)
        end

        # Get the inReplyTo property of the notification
        #
        # @return [String] the inReplyTo value
        def in_reply_to
          get_property(ActivityStreams2::Properties::IN_REPLY_TO)
        end

        # Set the inReplyTo property of the notification
        #
        # @param value [String] the inReplyTo value to set
        def in_reply_to=(value)
          set_property(ActivityStreams2::Properties::IN_REPLY_TO, value)
        end

        # Get the actor property of the notification
        #
        # @return [NotifyActor, nil] the actor
        def actor
          a = get_property(ActivityStreams2::Properties::ACTOR)
          if a
            NotifyActor.new(stream: a, validate_stream_on_construct: false,
                            validate_properties: @validate_properties, validators: @validators,
                            validation_context: ActivityStreams2::Properties::ACTOR,
                            properties_by_reference: @properties_by_reference)
          end
        end

        # Set the actor property of the notification
        #
        # @param value [NotifyActor] the actor to set
        def actor=(value)
          set_property(ActivityStreams2::Properties::ACTOR, value.doc)
        end

        # Get the context property of the notification
        #
        # @return [NotifyObject, nil] the context
        def context
          c = get_property(ActivityStreams2::Properties::CONTEXT)
          if c
            NotifyObject.new(stream: c, validate_stream_on_construct: false,
                             validate_properties: @validate_properties, validators: @validators,
                             validation_context: ActivityStreams2::Properties::CONTEXT,
                             properties_by_reference: @properties_by_reference)
          end
        end

        # Set the context property of the notification
        #
        # @param value [NotifyObject] the context to set
        def context=(value)
          set_property(ActivityStreams2::Properties::CONTEXT, value.doc)
        end

        # Base validator for all notification patterns. This extends the validate function on the superclass.
        #
        # In addition to the base class's constraints, this applies the following validation:
        #
        # * The origin, target and object properties are required and must be valid
        # * The actor inReplyTo and context properties are optional, but if present must be valid
        #
        # @return [Boolean] true if valid, otherwise raises ValidationError
        def validate
          ve = ValidationError.new
          begin
            super
          rescue ValidationError => superve
            ve = superve
          end

          required_and_validate(ve, ActivityStreams2::Properties::ORIGIN, origin)
          required_and_validate(ve, ActivityStreams2::Properties::TARGET, target)
          required_and_validate(ve, ActivityStreams2::Properties::OBJECT, object)
          optional_and_validate(ve, ActivityStreams2::Properties::ACTOR, actor)
          optional_and_validate(ve, ActivityStreams2::Properties::IN_REPLY_TO, in_reply_to)
          optional_and_validate(ve, ActivityStreams2::Properties::CONTEXT, context)

          raise ve if ve.has_errors?
          true
        end
      end

      # Base class for all pattern parts, such as objects, contexts, actors, etc
      #
      # If there is a default type specified, and a type is not given at construction, then
      # the default type will be added
      class NotifyPatternPart < NotifyBase
        # The default type for this object, if none is provided on construction
        def self.default_type
          nil
        end

        # The list of types that are permissible for this object. If the list is empty, then any type is allowed
        def self.allowed_types
          []
        end

        # Constructor for the NotifyPatternPart
        #
        # If there is a default type specified, and a type is not given at construction, then
        # the default type will be added
        #
        # @param stream [ActivityStreams2::ActivityStream, Hash] The activity stream object, or a hash from which one can be created
        # @param validate_stream_on_construct [Boolean] should the incoming stream be validated at construction-time
        # @param validate_properties [Boolean] should individual properties be validated as they are set
        # @param validators [Validate::Validator] the validator object for this class and all nested elements
        # @param validation_context [String, Array] the context in which this object is being validated
        # @param properties_by_reference [Boolean] should properties be get and set by reference (the default) or by value
        def initialize(stream: nil, validate_stream_on_construct: true, validate_properties: true,
                       validators: nil, validation_context: nil, properties_by_reference: true)
          super(stream: stream, validate_stream_on_construct: validate_stream_on_construct,
                validate_properties: validate_properties, validators: validators,
                validation_context: validation_context, properties_by_reference: properties_by_reference)
          self.type = self.class.default_type if self.class.default_type && type.nil?
        end

        # Get the allowed types for this object
        #
        # @return [Array<String>] the allowed types
        def allowed_types
          self.class.allowed_types
        end

        # Set the type of the object, and validate that it is one of the allowed types if present
        #
        # @param types [String, Array<String>] the type(s) to set
        def type=(types)
          types = [types] unless types.is_a?(Array)

          if !allowed_types.empty?
            types.each do |t|
              unless allowed_types.include?(t)
                raise ArgumentError, "Type value #{t} is not one of the permitted values"
              end
            end
          end

          # keep single values as single values, not arrays
          types = types.length == 1 ? types[0] : types

          set_property(ActivityStreams2::Properties::TYPE, types)
        end
      end

      # Default class to represent a service in the COAR Notify pattern.
      #
      # Services are used to represent origin and target properties in the notification patterns
      #
      # Specific patterns may need to extend this class to provide their specific behaviours and validation
      class NotifyService < NotifyPatternPart
        # The default type for a service is Service, but the type can be set to any value
        def self.default_type
          ActivityStreams2::ActivityStreamsTypes::SERVICE
        end

        # Get the inbox property of the service
        #
        # @return [String] the inbox URL
        def inbox
          get_property(NotifyProperties::INBOX)
        end

        # Set the inbox property of the service
        #
        # @param value [String] the inbox URL to set
        def inbox=(value)
          set_property(NotifyProperties::INBOX, value)
        end
      end

      # Default class to represent an object in the COAR Notify pattern. Objects can be used for object or context properties
      # in notify patterns
      #
      # Specific patterns may need to extend this class to provide their specific behaviours and validation
      class NotifyObject < NotifyPatternPart
        # Get the ietf:cite-as property of the object
        #
        # @return [String] the cite-as value
        def cite_as
          get_property(NotifyProperties::CITE_AS)
        end

        # Set the ietf:cite-as property of the object
        #
        # @param value [String] the cite-as value to set
        def cite_as=(value)
          set_property(NotifyProperties::CITE_AS, value)
        end

        # Get the ietf:item property of the object
        #
        # @return [NotifyItem, nil] the item
        def item
          i = get_property(NotifyProperties::ITEM)
          if i
            NotifyItem.new(stream: i, validate_stream_on_construct: false,
                           validate_properties: @validate_properties, validators: @validators,
                           validation_context: NotifyProperties::ITEM,
                           properties_by_reference: @properties_by_reference)
          end
        end

        # Set the ietf:item property of the object
        #
        # @param value [NotifyItem] the item to set
        def item=(value)
          set_property(NotifyProperties::ITEM, value)
        end

        # Get object, relationship and subject properties as a relationship triple
        #
        # @return [Array<String>] array of [object, relationship, subject]
        def triple
          obj = get_property(ActivityStreams2::Properties::OBJECT_TRIPLE)
          rel = get_property(ActivityStreams2::Properties::RELATIONSHIP_TRIPLE)
          subj = get_property(ActivityStreams2::Properties::SUBJECT_TRIPLE)
          [obj, rel, subj]
        end

        # Set object, relationship and subject properties as a relationship triple
        #
        # @param value [Array<String>] array of [object, relationship, subject]
        def triple=(value)
          obj, rel, subj = value
          set_property(ActivityStreams2::Properties::OBJECT_TRIPLE, obj)
          set_property(ActivityStreams2::Properties::RELATIONSHIP_TRIPLE, rel)
          set_property(ActivityStreams2::Properties::SUBJECT_TRIPLE, subj)
        end

        # Validate the object. This overrides the base validation, as objects only absolutely require an id property,
        # so the base requirement for a type is relaxed.
        #
        # @return [Boolean] true if valid, otherwise raises ValidationError
        def validate
          ve = ValidationError.new

          required_and_validate(ve, ActivityStreams2::Properties::ID, id)

          raise ve if ve.has_errors?
          true
        end
      end

      # Default class to represents an actor in the COAR Notify pattern.
      # Actors are used to represent the actor property in the notification patterns
      #
      # Specific patterns may need to extend this class to provide their specific behaviours and validation
      class NotifyActor < NotifyPatternPart
        # Default type is Service, but can also be set as any one of the other allowed types
        def self.default_type
          ActivityStreams2::ActivityStreamsTypes::SERVICE
        end

        # The allowed types for an actor: Service, Application, Group, Organisation, Person
        def self.allowed_types
          [
            ActivityStreams2::ActivityStreamsTypes::SERVICE,
            ActivityStreams2::ActivityStreamsTypes::APPLICATION,
            ActivityStreams2::ActivityStreamsTypes::GROUP,
            ActivityStreams2::ActivityStreamsTypes::ORGANIZATION,
            ActivityStreams2::ActivityStreamsTypes::PERSON
          ]
        end

        # Get the name property of the actor
        #
        # @return [String] the name
        def name
          get_property(NotifyProperties::NAME)
        end

        # Set the name property of the actor
        #
        # @param value [String] the name to set
        def name=(value)
          set_property(NotifyProperties::NAME, value)
        end
      end

      # Default class to represent an item in the COAR Notify pattern.
      # Items are used to represent the ietf:item property in the notification patterns
      #
      # Specific patterns may need to extend this class to provide their specific behaviours and validation
      class NotifyItem < NotifyPatternPart
        # Get the mediaType property of the item
        #
        # @return [String] the media type
        def media_type
          get_property(NotifyProperties::MEDIA_TYPE)
        end

        # Set the mediaType property of the item
        #
        # @param value [String] the media type to set
        def media_type=(value)
          set_property(NotifyProperties::MEDIA_TYPE, value)
        end

        # Validate the item. This overrides the base validation, as objects only absolutely require an id property,
        # so the base requirement for a type is relaxed.
        #
        # @return [Boolean] true if valid, otherwise raises ValidationError
        def validate
          ve = ValidationError.new

          required_and_validate(ve, ActivityStreams2::Properties::ID, id)

          raise ve if ve.has_errors?
          true
        end
      end

      # Mixins
      ##########################################################

      # A mixin to add to a pattern which can override the default object property to return a full
      # nested pattern from the object property, rather than the default NotifyObject
      #
      # This mixin needs to be included first, as it overrides the object property
      # of the NotifyPattern class.
      #
      # For example:
      #
      #   class MySpecialPattern < NotifyPattern
      #     include NestedPatternObjectMixin
      #   end
      module NestedPatternObjectMixin
        # Retrieve an object as it's correctly typed pattern, falling back to a default NotifyObject if no pattern matches
        #
        # @return [NotifyPattern, NotifyObject, nil] the object
        def object
          o = get_property(ActivityStreams2::Properties::OBJECT)
          if o
            # Try to get the factory class if it's available
            if defined?(::Coarnotify::Factory::COARNotifyFactory)
              begin
                nested = ::Coarnotify::Factory::COARNotifyFactory.get_by_object(o.dup,
                                                                                validate_stream_on_construct: false,
                                                                                validate_properties: @validate_properties,
                                                                                validators: @validators,
                                                                                validation_context: nil)  # don't supply a validation context, as these objects are not typical nested objects
                return nested if nested
              rescue => e
                # Fall back to generic object if factory fails
              end
            end

            # if we are unable to construct the typed nested object, just return a generic object
            NotifyObject.new(stream: o.dup, validate_stream_on_construct: false,
                             validate_properties: @validate_properties, validators: @validators,
                             validation_context: ActivityStreams2::Properties::OBJECT)
          end
        end

        # Set the object property
        #
        # @param value [NotifyObject, NotifyPattern] the object to set
        def object=(value)
          set_property(ActivityStreams2::Properties::OBJECT, value.doc)
        end
      end

      # Mixin to provide an API for setting and getting the summary property of a pattern
      module SummaryMixin
        # The summary property of the pattern
        #
        # @return [String] the summary
        def summary
          get_property(ActivityStreams2::Properties::SUMMARY)
        end

        # Set the summary property of the pattern
        #
        # @param summary [String] the summary to set
        def summary=(summary)
          set_property(ActivityStreams2::Properties::SUMMARY, summary)
        end
      end
    end
  end
end
