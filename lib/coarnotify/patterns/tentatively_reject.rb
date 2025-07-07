# frozen_string_literal: true

require_relative '../core/notify'
require_relative '../core/activity_streams2'
require_relative '../exceptions'

module Coarnotify
  module Patterns
    # Pattern to represent a TentativelyReject notification
    # https://coar-notify.net/specification/1.0.0/tentative-reject/
    class TentativelyReject < Core::Notify::NotifyPattern
      include Core::Notify::NestedPatternObjectMixin
      include Core::Notify::SummaryMixin

      def self.type_constant
        Core::ActivityStreams2::ActivityStreamsTypes::TENTATIVE_REJECT
      end

      def validate
        ve = ValidationError.new
        begin
          super
        rescue ValidationError => superve
          ve = superve
        end

        required_and_validate(ve, Core::ActivityStreams2::Properties::IN_REPLY_TO, in_reply_to)

        objid = object&.id
        if in_reply_to != objid
          ve.add_error(Core::ActivityStreams2::Properties::IN_REPLY_TO,
                       "Expected inReplyTo id to be the same as the nested object id. inReplyTo: #{in_reply_to}, object.id: #{objid}")
        end

        raise ve if ve.has_errors?
        true
      end
    end
  end
end
