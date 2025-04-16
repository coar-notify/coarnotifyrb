module COARNotify
    module Patterns
      # Pattern to represent Announce Service Result notification
      # https://coar-notify.net/specification/1.0.0/announce-resource/
      class AnnounceServiceResult < NotifyPattern
        # Announce Service Result type (ActivityStreams Announce type)
        TYPE = ActivityStreamsTypes::ANNOUNCE
  
        # Custom getter for object property as AnnounceServiceResultObject
        #
        # @return [AnnounceServiceResultObject, nil] The service result object
        def object
          o = get_property(Properties::OBJECT)
          if o
            AnnounceServiceResultObject.new(
              o,
              validate_stream_on_construct: false,
              validate_properties: validate_properties,
              validators: validators,
              validation_context: Properties::OBJECT,
              properties_by_reference: @properties_by_reference
            )
          end
        end
  
        # Custom getter for context property as AnnounceServiceResultContext
        #
        # @return [AnnounceServiceResultContext, nil] The service result context
        def context
          c = get_property(Properties::CONTEXT)
          if c
            AnnounceServiceResultContext.new(
              c,
              validate_stream_on_construct: false,
              validate_properties: validate_properties,
              validators: validators,
              validation_context: Properties::CONTEXT,
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
  
      # Custom context class for Announce Service Result
      class AnnounceServiceResultContext < NotifyObject
        # Custom getter for item property as AnnounceServiceResultItem
        #
        # @return [AnnounceServiceResultItem, nil] The service result item
        def item
          i = get_property(NotifyProperties::ITEM)
          if i
            AnnounceServiceResultItem.new(
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
      class AnnounceServiceResultItem < NotifyItem
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
  
      # Custom object class with additional validation
      class AnnounceServiceResultObject < NotifyObject
        # Extends base validation to make type required
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
  
          raise ve if ve.has_errors?
          true
        end
      end
    end
  end