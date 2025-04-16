module COARNotify
    module Patterns
      # Pattern to represent a Request Review notification
      # https://coar-notify.net/specification/1.0.0/request-review/
      class RequestReview < NotifyPattern
        # Request Review types including ActivityStreams offer and COAR Notify Review Action
        TYPE = [ActivityStreamsTypes::OFFER, NotifyTypes::REVIEW_ACTION]
  
        # Custom getter for object property as RequestReviewObject
        #
        # @return [RequestReviewObject, nil] The review request object
        def object
          o = get_property(Properties::OBJECT)
          if o
            RequestReviewObject.new(
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
  
      # Custom object class for Request Review
      class RequestReviewObject < NotifyObject
        # Custom getter for item property as RequestReviewItem
        #
        # @return [RequestReviewItem, nil] The review item
        def item
          i = get_property(NotifyProperties::ITEM)
          if i
            RequestReviewItem.new(
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
      class RequestReviewItem < NotifyItem
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