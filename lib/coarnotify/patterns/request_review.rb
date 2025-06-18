# frozen_string_literal: true

require_relative '../core/notify'
require_relative '../core/activity_streams2'
require_relative '../exceptions'

module Coarnotify
  module Patterns
    # Pattern to represent a Request Review notification
    # https://coar-notify.net/specification/1.0.0/request-review/
    class RequestReview < Core::Notify::NotifyPattern
      # Request Review types, including an ActivityStreams offer and a COAR Notify Review Action
      def self.type_constant
        [Core::ActivityStreams2::ActivityStreamsTypes::OFFER, Core::Notify::NotifyTypes::REVIEW_ACTION]
      end

      # Custom getter to retrieve the object property as a RequestReviewObject
      #
      # @return [RequestReviewObject, nil] the object
      def object
        o = get_property(Core::ActivityStreams2::Properties::OBJECT)
        if o
          RequestReviewObject.new(stream: o, validate_stream_on_construct: false,
                                  validate_properties: @validate_properties, validators: @validators,
                                  validation_context: Core::ActivityStreams2::Properties::OBJECT,
                                  properties_by_reference: @properties_by_reference)
        end
      end
    end

    # Custom Request Review Object class to return the custom RequestReviewItem class
    class RequestReviewObject < Core::Notify::NotifyObject
      # Custom getter to retrieve the item property as a RequestReviewItem
      #
      # @return [RequestReviewItem, nil] the item
      def item
        i = get_property(Core::Notify::NotifyProperties::ITEM)
        if i
          RequestReviewItem.new(stream: i, validate_stream_on_construct: false,
                                validate_properties: @validate_properties, validators: @validators,
                                validation_context: Core::Notify::NotifyProperties::ITEM,
                                properties_by_reference: @properties_by_reference)
        end
      end
    end

    # Custom Request Review Item class to provide the custom validation
    class RequestReviewItem < Core::Notify::NotifyItem
      # Extend the base validation to include the following constraints:
      #
      # * The type property is required and must validate
      # * the mediaType property is required
      #
      # @return [Boolean] true if validation passes, else raise a ValidationError
      def validate
        ve = ValidationError.new
        begin
          super
        rescue ValidationError => superve
          ve = superve
        end

        required_and_validate(ve, Core::ActivityStreams2::Properties::TYPE, type)
        required(ve, Core::Notify::NotifyProperties::MEDIA_TYPE, media_type)

        raise ve if ve.has_errors?
        true
      end
    end
  end
end
