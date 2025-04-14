module COARNotify
    module Patterns
      # Pattern to represent Announce Review notification
      # https://coar-notify.net/specification/1.0.0/announce-review/
      class AnnounceReview < NotifyPattern
        # Announce Review type including Activity Streams Announce and Notify Review Action
        TYPE = [ActivityStreamsTypes::ANNOUNCE, NotifyTypes::REVIEW_ACTION]
  
        # Custom getter to retrieve Announce Review object
        #
        # @return [AnnounceReviewObject, nil] The review object
        def object
          o = get_property(Properties::OBJECT)
          if o
            AnnounceReviewObject.new(
              o,
              validate_stream_on_construct: false,
              validate_properties: validate_properties,
              validators: validators,
              validation_context: Properties::OBJECT,
              properties_by_reference: @properties_by_reference
            )
          end
        end
  
        # Custom getter to retrieve AnnounceReview Context
        #
        # @return [AnnounceReviewContext, nil] The review context
        def context
          c = get_property(Properties::CONTEXT)
          if c
            AnnounceReviewContext.new(
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
  
      # Custom Context for Announce Review
      class AnnounceReviewContext < NotifyObject
        # Custom getter to retrieve AnnounceReviewItem
        #
        # @return [AnnounceReviewItem, nil] The review item
        def item
          i = get_property(NotifyProperties::ITEM)
          if i
            AnnounceReviewItem.new(
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
  
      # Custom AnnounceReviewItem with additional validation
      class AnnounceReviewItem < NotifyItem
        # Extends base validation to:
        # - Reintroduce type validation
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
  
      # Custom Announce Review Object with additional validation
      class AnnounceReviewObject < NotifyObject
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