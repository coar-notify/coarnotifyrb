# This module contains all core model objects for COAR Notify patterns
require 'json'
require 'securerandom'
require_relative 'activitystreams2'
require_relative '../validate'
require_relative '../exceptions'

module COARNotify
  NOTIFY_NAMESPACE = "https://coar-notify.net".freeze

  module NotifyProperties
    INBOX = ["inbox", NOTIFY_NAMESPACE].freeze
    CITE_AS = ["ietf:cite-as", NOTIFY_NAMESPACE].freeze
    ITEM = ["ietf:item", NOTIFY_NAMESPACE].freeze
    NAME = "name".freeze
    MEDIA_TYPE = "mediaType".freeze
  end

  module NotifyTypes
    ENDORSMENT_ACTION = "coar-notify:EndorsementAction".freeze
    INGEST_ACTION = "coar-notify:IngestAction".freeze
    RELATIONSHIP_ACTION = "coar-notify:RelationshipAction".freeze
    REVIEW_ACTION = "coar-notify:ReviewAction".freeze
    UNPROCESSABLE_NOTIFICATION = "coar-notify:UnprocessableNotification".freeze
    ABOUT_PAGE = "sorg:AboutPage".freeze
  end

  # Default validation rules
  VALIDATION_RULES = {
    Properties::ID => {
      "default" => Validate.method(:absolute_uri),
      "context" => {
        Properties::CONTEXT => { "default" => Validate.method(:url) },
        Properties::ORIGIN => { "default" => Validate.method(:url) },
        Properties::TARGET => { "default" => Validate.method(:url) },
        NotifyProperties::ITEM => { "default" => Validate.method(:url) }
      }
    },
    Properties::TYPE => {
      "default" => Validate.method(:type_checker),
      "context" => {
        Properties::ACTOR => {
          "default" => Validate.method(:one_of).call([
            ActivityStreamsTypes::SERVICE,
            ActivityStreamsTypes::APPLICATION,
            ActivityStreamsTypes::GROUP,
            ActivityStreamsTypes::ORGANIZATION,
            ActivityStreamsTypes::PERSON
          ])
        },
        Properties::OBJECT => {
          "default" => Validate.method(:at_least_one_of).call(ACTIVITY_STREAMS_OBJECTS)
        },
        Properties::CONTEXT => {
          "default" => Validate.method(:at_least_one_of).call(ACTIVITY_STREAMS_OBJECTS)
        },
        NotifyProperties::ITEM => {
          "default" => Validate.method(:at_least_one_of).call(ACTIVITY_STREAMS_OBJECTS)
        }
      }
    },
    NotifyProperties::CITE_AS => { "default" => Validate.method(:url) },
    NotifyProperties::INBOX => { "default" => Validate.method(:url) },
    Properties::IN_REPLY_TO => { "default" => Validate.method(:absolute_uri) },
    Properties::SUBJECT_TRIPLE => { "default" => Validate.method(:absolute_uri) },
    Properties::OBJECT_TRIPLE => { "default" => Validate.method(:absolute_uri) },
    Properties::RELATIONSHIP_TRIPLE => { "default" => Validate.method(:absolute_uri) }
  }.freeze

  VALIDATORS = Validate::Validator.new(VALIDATION_RULES)

  class NotifyBase
    attr_reader :validate_properties, :validate_stream_on_construct, :validators

    def initialize(stream = nil, validate_stream_on_construct: true, validate_properties: true,
                  validators: nil, validation_context: nil, properties_by_reference: true)
      @validate_stream_on_construct = validate_stream_on_construct
      @validate_properties = validate_properties
      @validators = validators || VALIDATORS
      @validation_context = validation_context
      @properties_by_reference = properties_by_reference
      validate_now = false

      if stream.nil?
        @stream = ActivityStream.new
      elsif stream.is_a?(Hash)
        validate_now = validate_stream_on_construct
        @stream = ActivityStream.new(stream)
      else
        validate_now = validate_stream_on_construct
        @stream = stream
      end

      if @stream.get_property(Properties::ID).nil?
        @stream.set_property(Properties::ID, "urn:uuid:#{SecureRandom.hex}")
      end

      validate if validate_now
    end

    def doc
      @stream.doc
    end

    def id
      get_property(Properties::ID)
    end

    def id=(value)
      set_property(Properties::ID, value)
    end

    def type
      get_property(Properties::TYPE)
    end

    def type=(types)
      set_property(Properties::TYPE, types)
    end

    def get_property(prop_name, by_reference: nil)
      by_reference = @properties_by_reference if by_reference.nil?
      val = @stream.get_property(prop_name)
      by_reference ? val : val.dup
    end

    def set_property(prop_name, value, by_reference: nil)
      by_reference = @properties_by_reference if by_reference.nil?
      validate_property(prop_name, value)
      value = value.dup unless by_reference
      @stream.set_property(prop_name, value)
    end

    def validate
      ve = ValidationError.new
      required_and_validate(ve, Properties::ID, id)
      required_and_validate(ve, Properties::TYPE, type)

      raise ve if ve.has_errors?
      true
    end

    def validate_property(prop_name, value, force_validate: false, raise_error: true)
      return [true, ""] if value.nil?

      if @validate_properties || force_validate
        validator = @validators.get(prop_name, @validation_context)
        if validator
          begin
            validator.call(self, value)
          rescue => e
            if raise_error
              raise e
            else
              return [false, e.message]
            end
          end
        end
      end
      [true, ""]
    end

    def required(ve, prop_name, value)
      if value.nil?
        pn = prop_name.is_a?(Array) ? prop_name.first : prop_name
        ve.add_error(prop_name, Validate::REQUIRED_MESSAGE % {x: pn})
      end
    end

    def required_and_validate(ve, prop_name, value)
      if value.nil?
        required(ve, prop_name, value)
      else
        if value.is_a?(NotifyBase)
          begin
            value.validate
          rescue ValidationError => e
            ve.add_nested_errors(prop_name, e)
          end
        else
          _register_property_validation_error(ve, prop_name, value)
        end
      end
    end

    def optional_and_validate(ve, prop_name, value)
      return if value.nil?

      if value.is_a?(NotifyBase)
        begin
          value.validate
        rescue ValidationError => e
          ve.add_nested_errors(prop_name, e)
        end
      else
        _register_property_validation_error(ve, prop_name, value)
      end
    end

    def to_jsonld
      @stream.to_jsonld
    end

    private

    def _register_property_validation_error(ve, prop_name, value)
      valid, msg = validate_property(prop_name, value, force_validate: true, raise_error: false)
      ve.add_error(prop_name, msg) unless valid
    end
  end

  class NotifyPattern < NotifyBase
    TYPE = ActivityStreamsTypes::OBJECT

    def initialize(stream = nil, validate_stream_on_construct: true, validate_properties: true,
                  validators: nil, validation_context: nil, properties_by_reference: true)
      super(stream, validate_stream_on_construct: validate_stream_on_construct,
            validate_properties: validate_properties, validators: validators,
            validation_context: validation_context, properties_by_reference: properties_by_reference)
      _ensure_type_contains(self.class::TYPE)
    end

    def origin
      o = get_property(Properties::ORIGIN)
      o ? NotifyService.new(o, validate_stream_on_construct: false,
                           validate_properties: @validate_properties,
                           validators: @validators,
                           validation_context: Properties::ORIGIN,
                           properties_by_reference: @properties_by_reference) : nil
    end

    def origin=(value)
      set_property(Properties::ORIGIN, value.doc)
    end

    def target
      t = get_property(Properties::TARGET)
      t ? NotifyService.new(t, validate_stream_on_construct: false,
                           validate_properties: @validate_properties,
                           validators: @validators,
                           validation_context: Properties::TARGET,
                           properties_by_reference: @properties_by_reference) : nil
    end

    def target=(value)
      set_property(Properties::TARGET, value.doc)
    end

    def object
      o = get_property(Properties::OBJECT)
      o ? NotifyObject.new(o, validate_stream_on_construct: false,
                          validate_properties: @validate_properties,
                          validators: @validators,
                          validation_context: Properties::OBJECT,
                          properties_by_reference: @properties_by_reference) : nil
    end

    def object=(value)
      set_property(Properties::OBJECT, value.doc)
    end

    def in_reply_to
      get_property(Properties::IN_REPLY_TO)
    end

    def in_reply_to=(value)
      set_property(Properties::IN_REPLY_TO, value)
    end

    def actor
      a = get_property(Properties::ACTOR)
      a ? NotifyActor.new(a, validate_stream_on_construct: false,
                         validate_properties: @validate_properties,
                         validators: @validators,
                         validation_context: Properties::ACTOR,
                         properties_by_reference: @properties_by_reference) : nil
    end

    def actor=(value)
      set_property(Properties::ACTOR, value.doc)
    end

    def context
      c = get_property(Properties::CONTEXT)
      c ? NotifyObject.new(c, validate_stream_on_construct: false,
                          validate_properties: @validate_properties,
                          validators: @validators,
                          validation_context: Properties::CONTEXT,
                          properties_by_reference: @properties_by_reference) : nil
    end

    def context=(value)
      set_property(Properties::CONTEXT, value.doc)
    end

    def validate
      ve = ValidationError.new
      begin
        super
      rescue ValidationError => e
        ve = e
      end

      required_and_validate(ve, Properties::ORIGIN, origin)
      required_and_validate(ve, Properties::TARGET, target)
      required_and_validate(ve, Properties::OBJECT, object)
      optional_and_validate(ve, Properties::ACTOR, actor)
      optional_and_validate(ve, Properties::IN_REPLY_TO, in_reply_to)
      optional_and_validate(ve, Properties::CONTEXT, context)

      raise ve if ve.has_errors?
      true
    end

    private

    def _ensure_type_contains(types)
      existing = @stream.get_property(Properties::TYPE)
      if existing.nil?
        set_property(Properties::TYPE, types)
      else
        existing = [existing] unless existing.is_a?(Array)
        types = [types] unless types.is_a?(Array)
        types.each { |t| existing << t unless existing.include?(t) }
        set_property(Properties::TYPE, existing.size == 1 ? existing.first : existing)
      end
    end
  end

  class NotifyPatternPart < NotifyBase
    DEFAULT_TYPE = nil
    ALLOWED_TYPES = []

    def initialize(stream = nil, validate_stream_on_construct: true, validate_properties: true,
                  validators: nil, validation_context: nil, properties_by_reference: true)
      super(stream, validate_stream_on_construct: validate_stream_on_construct,
            validate_properties: validate_properties, validators: validators,
            validation_context: validation_context, properties_by_reference: properties_by_reference)
      self.type = self.class::DEFAULT_TYPE if self.class::DEFAULT_TYPE && type.nil?
    end

    def type=(types)
      types = [types] unless types.is_a?(Array)

      if !self.class::ALLOWED_TYPES.empty?
        types.each do |t|
          unless self.class::ALLOWED_TYPES.include?(t)
            raise "Type value #{t} is not one of the permitted values"
          end
        end
      end

      set_property(Properties::TYPE, types.size == 1 ? types.first : types)
    end
  end

  class NotifyService < NotifyPatternPart
    DEFAULT_TYPE = ActivityStreamsTypes::SERVICE

    def inbox
      get_property(NotifyProperties::INBOX)
    end

    def inbox=(value)
      set_property(NotifyProperties::INBOX, value)
    end
  end

  class NotifyObject < NotifyPatternPart
    def cite_as
      get_property(NotifyProperties::CITE_AS)
    end

    def cite_as=(value)
      set_property(NotifyProperties::CITE_AS, value)
    end

    def item
      i = get_property(NotifyProperties::ITEM)
      i ? NotifyItem.new(i, validate_stream_on_construct: false,
                        validate_properties: @validate_properties,
                        validators: @validators,
                        validation_context: NotifyProperties::ITEM,
                        properties_by_reference: @properties_by_reference) : nil
    end

    def item=(value)
      set_property(NotifyProperties::ITEM, value.doc)
    end

    def triple
      [
        get_property(Properties::OBJECT_TRIPLE),
        get_property(Properties::RELATIONSHIP_TRIPLE),
        get_property(Properties::SUBJECT_TRIPLE)
      ]
    end

    def triple=(value)
      obj, rel, subj = value
      set_property(Properties::OBJECT_TRIPLE, obj)
      set_property(Properties::RELATIONSHIP_TRIPLE, rel)
      set_property(Properties::SUBJECT_TRIPLE, subj)
    end

    def validate
      ve = ValidationError.new
      required_and_validate(ve, Properties::ID, id)
      raise ve if ve.has_errors?
      true
    end
  end

  class NotifyActor < NotifyPatternPart
    DEFAULT_TYPE = ActivityStreamsTypes::SERVICE
    ALLOWED_TYPES = [
      DEFAULT_TYPE,
      ActivityStreamsTypes::APPLICATION,
      ActivityStreamsTypes::GROUP,
      ActivityStreamsTypes::ORGANIZATION,
      ActivityStreamsTypes::PERSON
    ].freeze

    def name
      get_property(NotifyProperties::NAME)
    end

    def name=(value)
      set_property(NotifyProperties::NAME, value)
    end
  end

  class NotifyItem < NotifyPatternPart
    def media_type
      get_property(NotifyProperties::MEDIA_TYPE)
    end

    def media_type=(value)
      set_property(NotifyProperties::MEDIA_TYPE, value)
    end

    def validate
      ve = ValidationError.new
      required_and_validate(ve, Properties::ID, id)
      raise ve if ve.has_errors?
      true
    end
  end

  module NestedPatternObjectMixin
    def object
      o = get_property(Properties::OBJECT)
      if o
        nested = COARNotify::Factory.get_by_object(o.dup,
                                                  validate_stream_on_construct: false,
                                                  validate_properties: @validate_properties,
                                                  validators: @validators,
                                                  validation_context: nil)
        return nested if nested

        NotifyObject.new(o.dup,
                        validate_stream_on_construct: false,
                        validate_properties: @validate_properties,
                        validators: @validators,
                        validation_context: Properties::OBJECT)
      end
    end

    def object=(value)
      set_property(Properties::OBJECT, value.doc)
    end
  end

  module SummaryMixin
    def summary
      get_property(Properties::SUMMARY)
    end

    def summary=(value)
      set_property(Properties::SUMMARY, value)
    end
  end
end