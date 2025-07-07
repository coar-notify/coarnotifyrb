# frozen_string_literal: true

require_relative '../core/notify'
require_relative '../core/activity_streams2'

module Coarnotify
  module Patterns
    # Pattern to represent a RequestEndorsement notification
    class RequestEndorsement < Core::Notify::NotifyPattern
      def self.type_constant
        [Core::ActivityStreams2::ActivityStreamsTypes::OFFER, Core::Notify::NotifyTypes::ENDORSEMENT_ACTION]
      end

      # Custom getter to retrieve the object property as a RequestEndorsementObject
      #
      # @return [RequestEndorsementObject, nil] the object
      def object
        o = get_property(Core::ActivityStreams2::Properties::OBJECT)
        if o
          RequestEndorsementObject.new(stream: o, validate_stream_on_construct: false,
                                       validate_properties: @validate_properties, validators: @validators,
                                       validation_context: Core::ActivityStreams2::Properties::OBJECT,
                                       properties_by_reference: @properties_by_reference)
        end
      end

      # Set the object property of the notification
      #
      # @param value [RequestEndorsementObject] the object to set
      def object=(value)
        set_property(Core::ActivityStreams2::Properties::OBJECT, value.doc)
      end
    end

    # Custom object class for Request Endorsement to provide the custom item getter
    class RequestEndorsementObject < Core::Notify::NotifyObject
      # Custom getter to retrieve the item property as a RequestEndorsementItem
      #
      # @return [RequestEndorsementItem, nil] the item
      def item
        i = get_property(Core::Notify::NotifyProperties::ITEM)
        if i
          RequestEndorsementItem.new(stream: i, validate_stream_on_construct: false,
                                     validate_properties: @validate_properties, validators: @validators,
                                     validation_context: Core::Notify::NotifyProperties::ITEM,
                                     properties_by_reference: @properties_by_reference)
        end
      end

      # Set the item property
      #
      # @param value [RequestEndorsementItem] the item to set
      def item=(value)
        set_property(Core::Notify::NotifyProperties::ITEM, value.doc)
      end
    end

    # Custom item class for Request Endorsement to provide the custom validation
    class RequestEndorsementItem < Core::Notify::NotifyItem
      # Extend the base validation to include the following constraints:
      #
      # * The item type is required and must validate
      # * The mediaType property is required
      #
      # @return [Boolean] true if validation passes, otherwise raise a ValidationError
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
  end
end
