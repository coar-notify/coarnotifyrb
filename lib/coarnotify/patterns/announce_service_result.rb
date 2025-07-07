# frozen_string_literal: true

require_relative '../core/notify'
require_relative '../core/activity_streams2'

module Coarnotify
  module Patterns
    # Pattern to represent the Announce Service Result notification
    # https://coar-notify.net/specification/1.0.0/announce-resource/
    class AnnounceServiceResult < Core::Notify::NotifyPattern
      def self.type_constant
        [Core::ActivityStreams2::ActivityStreamsTypes::ANNOUNCE, Core::Notify::NotifyTypes::INGEST_ACTION]
      end

      # Custom getter to retrieve the object property as an AnnounceServiceResultObject
      #
      # @return [AnnounceServiceResultObject, nil] AnnounceServiceResultObject
      def object
        o = get_property(Core::ActivityStreams2::Properties::OBJECT)
        if o
          AnnounceServiceResultObject.new(stream: o, validate_stream_on_construct: false,
                                          validate_properties: @validate_properties, validators: @validators,
                                          validation_context: Core::ActivityStreams2::Properties::OBJECT,
                                          properties_by_reference: @properties_by_reference)
        end
      end

      # Set the object property of the notification
      #
      # @param value [AnnounceServiceResultObject] the object to set
      def object=(value)
        set_property(Core::ActivityStreams2::Properties::OBJECT, value.doc)
      end

      # Custom getter to retrieve the context property as an AnnounceServiceResultContext
      #
      # @return [AnnounceServiceResultContext, nil] AnnounceServiceResultContext
      def context
        c = get_property(Core::ActivityStreams2::Properties::CONTEXT)
        if c
          AnnounceServiceResultContext.new(stream: c, validate_stream_on_construct: false,
                                           validate_properties: @validate_properties, validators: @validators,
                                           validation_context: Core::ActivityStreams2::Properties::CONTEXT,
                                           properties_by_reference: @properties_by_reference)
        end
      end

      # Set the context property of the notification
      #
      # @param value [AnnounceServiceResultContext] the context to set
      def context=(value)
        set_property(Core::ActivityStreams2::Properties::CONTEXT, value.doc)
      end

      # Extends the base validation to make `context` required
      #
      # @return [Boolean] true if valid, otherwise raises ValidationError
      def validate
        ve = Core::Notify::ValidationError.new

        begin
          super
        rescue Core::Notify::ValidationError => superve
          ve = superve
        end

        required_and_validate(ve, Core::ActivityStreams2::Properties::CONTEXT, context)

        raise ve if ve.has_errors?
        true
      end
    end

    # Custom object class for Announce Service Result to provide the custom item getter
    class AnnounceServiceResultContext < Core::Notify::NotifyObject
      # Custom getter to retrieve the item property as an AnnounceServiceResultItem
      #
      # @return [AnnounceServiceResultItem, nil] the item
      def item
        i = get_property(Core::Notify::NotifyProperties::ITEM)
        if i
          AnnounceServiceResultItem.new(stream: i, validate_stream_on_construct: false,
                                        validate_properties: @validate_properties, validators: @validators,
                                        validation_context: Core::Notify::NotifyProperties::ITEM,
                                        properties_by_reference: @properties_by_reference)
        end
      end

      # Set the item property
      #
      # @param value [AnnounceServiceResultItem] the item to set
      def item=(value)
        set_property(Core::Notify::NotifyProperties::ITEM, value.doc)
      end
    end

    # Custom item class for Announce Service Result to apply the custom validation
    class AnnounceServiceResultItem < Core::Notify::NotifyItem
      # Beyond the base validation, apply the following:
      #
      # * Make type required and valid
      # * Make the mediaType required
      #
      # @return [Boolean] true if validation passes, else raise a ValidationError
      def validate
        ve = Core::Notify::ValidationError.new

        begin
          super
        rescue Core::Notify::ValidationError => superve
          ve = superve
        end

        required_and_validate(ve, Core::ActivityStreams2::Properties::TYPE, type)
        required(ve, Core::Notify::NotifyProperties::MEDIA_TYPE, media_type)

        raise ve if ve.has_errors?
        true
      end
    end

    # Custom object class for Announce Service Result to apply the custom validation
    class AnnounceServiceResultObject < Core::Notify::NotifyObject
      # Extend the base validation to include the following constraints:
      #
      # * The object type is required and must validate
      #
      # @return [Boolean] true if validation passes, else raise a ValidationError
      def validate
        ve = Core::Notify::ValidationError.new

        begin
          super
        rescue Core::Notify::ValidationError => superve
          ve = superve
        end

        required_and_validate(ve, Core::ActivityStreams2::Properties::TYPE, type)

        raise ve if ve.has_errors?
        true
      end
    end
  end
end
