# frozen_string_literal: true

require_relative '../core/notify'
require_relative '../core/activity_streams2'
require_relative '../exceptions'

module Coarnotify
  module Patterns
    # Pattern to represent the Unprocessable Notification notification
    # https://coar-notify.net/specification/1.0.0/unprocessable/
    class UnprocessableNotification < Core::Notify::NotifyPattern
      include Core::Notify::SummaryMixin

      def self.type_constant
        Core::Notify::NotifyTypes::UNPROCESSABLE_NOTIFICATION
      end

      # In addition to the base validation apply the following constraints:
      #
      # * The inReplyTo property is required
      # * The summary property is required
      #
      # @return [Boolean] true if validation passes, otherwise raise a ValidationError
      def validate
        ve = ValidationError.new
        begin
          super
        rescue ValidationError => superve
          ve = superve
        end

        # Technically, no need to validate the value, as this is handled by the superclass,
        # but leaving it in for completeness
        required_and_validate(ve, Core::ActivityStreams2::Properties::IN_REPLY_TO, in_reply_to)
        required(ve, Core::ActivityStreams2::Properties::SUMMARY, summary)

        raise ve if ve.has_errors?
        true
      end
    end
  end
end
