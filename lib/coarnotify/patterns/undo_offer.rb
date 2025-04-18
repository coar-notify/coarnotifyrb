module COARNotify
    module Patterns
      # Pattern to represent an Unprocessable Notification
      # https://coar-notify.net/specification/1.0.0/unprocessable/
      class UnprocessableNotification < NotifyPattern
        include SummaryMixin
  
        # Unprocessable Notification types including ActivityStreams Flag and COAR Notify Unprocessable Notification
        TYPE = [ActivityStreamsTypes::FLAG, NotifyTypes::UNPROCESSABLE_NOTIFICATION]
  
        # Validates the UnprocessableNotification pattern with additional constraints:
        # - inReplyTo property is required
        # - summary property is required
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
  
          # Validate required fields
          required_and_validate(ve, Properties::IN_REPLY_TO, in_reply_to)
          required(ve, Properties::SUMMARY, summary)
  
          raise ve if ve.has_errors?
          true
        end
      end
    end
  end