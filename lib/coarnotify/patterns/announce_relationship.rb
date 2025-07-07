# frozen_string_literal: true

require_relative '../core/notify'
require_relative '../core/activity_streams2'

module Coarnotify
  module Patterns
    # Pattern to represent an AnnounceRelationship notification
    class AnnounceRelationship < Core::Notify::NotifyPattern
      def self.type_constant
        [Core::ActivityStreams2::ActivityStreamsTypes::ANNOUNCE, Core::Notify::NotifyTypes::RELATIONSHIP_ACTION]
      end

      # Custom getter to retrieve the object property as an AnnounceRelationshipObject
      #
      # @return [AnnounceRelationshipObject, nil] the object
      def object
        o = get_property(Core::ActivityStreams2::Properties::OBJECT)
        if o
          AnnounceRelationshipObject.new(stream: o, validate_stream_on_construct: false,
                                         validate_properties: @validate_properties, validators: @validators,
                                         validation_context: Core::ActivityStreams2::Properties::OBJECT,
                                         properties_by_reference: @properties_by_reference)
        end
      end

      # Set the object property of the notification
      #
      # @param value [AnnounceRelationshipObject] the object to set
      def object=(value)
        set_property(Core::ActivityStreams2::Properties::OBJECT, value.doc)
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

    # Custom object class for Announce Relationship to apply the custom validation
    class AnnounceRelationshipObject < Core::Notify::NotifyObject
      # Extend the base validation to include the following constraints:
      #
      # * The object type is required and must validate
      # * The as:subject property is required
      # * The as:object property is required
      # * The as:relationship property is required
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
        required_and_validate(ve, Core::ActivityStreams2::Properties::SUBJECT_TRIPLE, subject)
        required_and_validate(ve, Core::ActivityStreams2::Properties::OBJECT_TRIPLE, object_triple)
        required_and_validate(ve, Core::ActivityStreams2::Properties::RELATIONSHIP_TRIPLE, relationship)

        raise ve if ve.has_errors?
        true
      end
    end
  end
end
