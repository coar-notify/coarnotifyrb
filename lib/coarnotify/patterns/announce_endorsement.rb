# coarnotify/patterns/announce_endorsement.rb
module COARNotify
    module Patterns
      # Pattern to represent an Announce Endorsement notification
      # https://coar-notify.net/specification/1.0.0/announce-endorsement/
      class AnnounceEndorsement < NotifyPattern
        # Announce Endorsement type, consisting of Activity Streams Announce and Notify Endorsement Action
        TYPE = [ActivityStreamsTypes::ANNOUNCE, NotifyTypes::ENDORSMENT_ACTION]
  
        # Get a context specific to Announce Endorsement
        #
        # @return [AnnounceEndorsementContext, nil] The Announce Endorsement context object
        def context
          c = get_property(Properties::CONTEXT)
          if c
            AnnounceEndorsementContext.new(
              c,
              validate_stream_on_construct: false,
              validate_properties: validate_properties,
              validators: validators,
              validation_context: Properties::CONTEXT,
              properties_by_reference: @properties_by_reference
            )
          end
        end
  
        # Extends the base validation to make `context` required
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
  
      # Announce Endorsement context object
      class AnnounceEndorsementContext < NotifyObject
        # Get a custom AnnounceEndorsementItem
        #
        # @return [AnnounceEndorsementItem, nil] the Announce Endorsement Item
        def item
          i = get_property(NotifyProperties::ITEM)
          if i
            AnnounceEndorsementItem.new(
              i,
              validate_stream_on_construct: false,
              validate_properties: validate_properties,
              validators: validators,
              validation_context: NotifyProperties::ITEM,
              properties_by_reference: @properties_by_reference
            )
          end
        end
      end
  
      # Announce Endorsement Item
      class AnnounceEndorsementItem < NotifyItem
        # Extends the base validation with custom validation:
        # - Adds type validation
        # - Requires mediaType value
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
          required(ve, NotifyProperties::MEDIA_TYPE, media_type)
  
          raise ve if ve.has_errors?
          true
        end
      end
    end
  end