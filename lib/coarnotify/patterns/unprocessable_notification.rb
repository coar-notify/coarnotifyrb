module COARNotify
    module Patterns
      class UnprocessableNotification < NotifyPattern
        include SummaryMixin
  
        TYPE = [ActivityStreamsTypes::FLAG, NotifyTypes::UNPROCESSABLE_NOTIFICATION]
  
        def validate
          ve = ValidationError.new
          begin
            super
          rescue ValidationError => superve
            ve = superve
          end
  
          required_and_validate(ve, Properties::IN_REPLY_TO, in_reply_to)
          required(ve, Properties::SUMMARY, summary)
  
          raise ve if ve.has_errors?
          true
        end
      end
    end
  end