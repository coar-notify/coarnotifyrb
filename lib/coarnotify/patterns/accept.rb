# frozen_string_literal: true

require_relative '../core/notify'
require_relative '../core/activity_streams2'
require_relative '../exceptions'

module Coarnotify
  module Patterns
    # Pattern to represent an Accept notification
    # https://coar-notify.net/specification/1.0.0/accept/
    class Accept < Core::Notify::NotifyPattern
      include Core::Notify::NestedPatternObjectMixin

      # The Accept type
      def self.type_constant
        Core::ActivityStreams2::ActivityStreamsTypes::ACCEPT
      end

      # Validate the Accept pattern.
      #
      # In addition to the base validation, this:
      #
      # * Makes inReplyTo required
      # * Requires the inReplyTo value to be the same as the object.id value
      #
      # @return [Boolean] true if valid, otherwise raises ValidationError
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
