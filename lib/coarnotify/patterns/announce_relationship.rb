# coarnotify/patterns/announce_relationship.rb
module COARNotify
    module Patterns
      # Pattern to represent an Announce Relationship notification
      # https://coar-notify.net/specification/1.0.0/announce-relationship/
      class AnnounceRelationship < NotifyPattern
        # Announce Relationship types including ActivityStreams announce and COAR Notify Relationship Action
        TYPE = [ActivityStreamsTypes::ANNOUNCE, NotifyTypes::RELATIONSHIP_ACTION]
  
        # Custom getter to retrieve the object property as an AnnounceRelationshipObject
        #
        # @return [AnnounceRelationshipObject, nil] The relationship object
        def object
          o = get_property(Properties::OBJECT)
          if o
            AnnounceRelationshipObject.new(
              o,
              validate_stream_on_construct: false,
              validate_properties: validate_properties,
              validators: validators,
              validation_context: Properties::OBJECT,
              properties_by_reference: @properties_by_reference
            )
          end
        end
  
        # Extends base validation to make context required
        #
        # @return [Boolean] true if valid
        # @raise [ValidationError] if validation fails
        def validate
          ve = ValidationError.new
          begin
            super
          rescue ValidationError => superve
            ve = superve
          end
  
          required_and_validate(ve, Properties::CONTEXT, context)
  
          raise ve if ve.has_errors?
          true
        end
      end
  
      # Custom object class for Announce Relationship with special validation
      class AnnounceRelationshipObject < NotifyObject
        # Extends base validation with relationship-specific constraints:
        # - Requires type property
        # - Validates relationship triple components
        #
        # @return [Boolean] true if valid
        # @raise [ValidationError] if validation fails
        def validate
          ve = ValidationError.new
          begin
            super
          rescue ValidationError => superve
            ve = superve
          end
  
          required_and_validate(ve, Properties::TYPE, type)
  
          subject, relationship, obj = triple
          required_and_validate(ve, Properties::SUBJECT_TRIPLE, subject)
          required_and_validate(ve, Properties::RELATIONSHIP_TRIPLE, relationship)
          required_and_validate(ve, Properties::OBJECT_TRIPLE, obj)
  
          raise ve if ve.has_errors?
          true
        end
      end
    end
  end