# frozen_string_literal: true

require_relative '../core/notify'
require_relative '../core/activity_streams2'

module Coarnotify
  module Patterns
    # Pattern to represent an AnnounceReview notification
    class AnnounceReview < Core::Notify::NotifyPattern
      def self.type_constant
        [Core::ActivityStreams2::ActivityStreamsTypes::ANNOUNCE, Core::Notify::NotifyTypes::REVIEW_ACTION]
      end

      # Custom getter to retrieve Announce Review object
      #
      # @return [AnnounceReviewObject, nil] Announce Review Object
      def object
        o = get_property(Core::ActivityStreams2::Properties::OBJECT)
        if o
          AnnounceReviewObject.new(stream: o, validate_stream_on_construct: false,
                                   validate_properties: @validate_properties, validators: @validators,
                                   validation_context: Core::ActivityStreams2::Properties::OBJECT,
                                   properties_by_reference: @properties_by_reference)
        end
      end

      # Set the object property of the notification
      #
      # @param value [AnnounceReviewObject] the object to set
      def object=(value)
        set_property(Core::ActivityStreams2::Properties::OBJECT, value.doc)
      end

      # Custom getter to retrieve AnnounceReview Context
      #
      # @return [AnnounceReviewContext, nil] AnnounceReviewContext
      def context
        c = get_property(Core::ActivityStreams2::Properties::CONTEXT)
        if c
          AnnounceReviewContext.new(stream: c, validate_stream_on_construct: false,
                                    validate_properties: @validate_properties, validators: @validators,
                                    validation_context: Core::ActivityStreams2::Properties::CONTEXT,
                                    properties_by_reference: @properties_by_reference)
        end
      end

      # Set the context property of the notification
      #
      # @param value [AnnounceReviewContext] the context to set
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

    # Custom Context for Announce Review, specifically to return custom
    # Announce Review Item
    class AnnounceReviewContext < Core::Notify::NotifyObject
      # Custom getter to retrieve AnnounceReviewItem
      #
      # @return [AnnounceReviewItem, nil] AnnounceReviewItem
      def item
        i = get_property(Core::Notify::NotifyProperties::ITEM)
        if i
          AnnounceReviewItem.new(stream: i, validate_stream_on_construct: false,
                                 validate_properties: @validate_properties, validators: @validators,
                                 validation_context: Core::Notify::NotifyProperties::ITEM,
                                 properties_by_reference: @properties_by_reference)
        end
      end

      # Set the item property
      #
      # @param value [AnnounceReviewItem] the item to set
      def item=(value)
        set_property(Core::Notify::NotifyProperties::ITEM, value.doc)
      end
    end

    # Custom AnnounceReviewItem which provides additional validation over the basic NotifyItem
    class AnnounceReviewItem < Core::Notify::NotifyItem
      # In addition to the base validator, this:
      #
      # * Reintroduces type validation
      # * make mediaType a required field
      #
      # @return [Boolean] true if valid, else raises a ValidationError
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

    # Custom Announce Review Object to apply custom validation for this pattern
    class AnnounceReviewObject < Core::Notify::NotifyObject
      # In addition to the base validator this:
      #
      # * Makes type required
      #
      # @return [Boolean] true if valid, else raises ValidationError
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
