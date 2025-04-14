module COARNotify
  module Patterns
    # Pattern to represent an Accept notification
    # https://coar-notify.net/specification/1.0.0/accept/
    class Accept < NotifyPattern
      include NestedPatternObjectMixin
      include SummaryMixin

      # Accept type (ActivityStreams Accept type)
      TYPE = ActivityStreamsTypes::ACCEPT

      # Validates the Accept pattern with additional constraints:
      # - inReplyTo property is required
      # - inReplyTo value must match object.id value
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

        # Validate inReplyTo presence
        required_and_validate(ve, Properties::IN_REPLY_TO, in_reply_to)

        # Validate inReplyTo matches object.id
        obj_id = object ? object.id : nil
        if in_reply_to != obj_id
          ve.add_error(
            Properties::IN_REPLY_TO,
            "Expected inReplyTo to match object.id. inReplyTo: #{in_reply_to}, object.id: #{obj_id}"
          )
        end

        raise ve if ve.has_errors?
        true
      end
    end
  end
end