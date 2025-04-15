module COARNotify
    module Patterns
      # Pattern to represent a Request Endorsement notification
      # https://coar-notify.net/specification/1.0.0/request-endorsement/
      class RequestEndorsement < NotifyPattern
        # Request Endorsement types including ActivityStreams offer and COAR Notify Endorsement Action
        TYPE = [ActivityStreamsTypes::OFFER, NotifyTypes::ENDORSMENT_ACTION]
  
        # Custom getter for object property as RequestEndorsementObject
        #
        # @return [RequestEndorsementObject, nil] The endorsement request object
        def object
          o = get_property(Properties::OBJECT)
          if o
            RequestEndorsementObject.new(
              o,
              validate_stream_on_construct: false,
              validate_properties: validate_properties,
              validators: validators,
              validation_context: Properties::OBJECT,
              properties_by_reference: @properties_by_reference
            )
          end
        end
      end
  
      # Custom object class for Request Endorsement
      class RequestEndorsementObject < NotifyObject
        # Custom getter for item property as RequestEndorsementItem
        #
        # @return [RequestEndorsementItem, nil] The endorsement item
        def item
          i = get_property(NotifyProperties::ITEM)
          if i
            RequestEndorsementItem.new(
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
  
      # Custom item class with additional validation
      class RequestEndorsementItem < NotifyItem
        # Extends base validation to:
        # - Make type required and valid
        # - Make mediaType required
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