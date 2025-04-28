# This module contains all the client-specific code for sending notifications
# to an inbox and receiving the responses it may return

require 'json'
require_relative 'exceptions'
require_relative 'http'
require_relative 'core/notify'

module COARNotify
  class NotifyResponse
    # An object representing the response from a COAR Notify inbox.
    # This contains the action that was carried out on the server:
    # * CREATED - a new resource was created
    # * ACCEPTED - the request was accepted, but the resource was not yet created
    # In the event that the resource is created, then there will also be a location
    # URL which will give you access to the resource
    
    CREATED = "created".freeze
    ACCEPTED = "accepted".freeze

    attr_reader :action, :location

    # Construct a new NotifyResponse object
    # @param action [String] The action which the server said it took
    # @param location [String, nil] The HTTP URI for the resource that was created
    def initialize(action, location = nil)
      @action = action
      @location = location
    end
  end

  class Client
    # The COAR Notify Client for interacting with external inboxes
    # @param inbox_url [String, nil] HTTP URI of the inbox to communicate with by default
    # @param http_layer [HttpLayer] HTTP implementation to use (defaults to NetHttpLayer)
    def initialize(inbox_url = nil, http_layer = nil)
      @inbox_url = inbox_url
      @http = http_layer || NetHttpLayer.new
    end

    # @return [String, nil] The HTTP URI of the inbox to communicate with by default
    attr_accessor :inbox_url

    # Send the given notification to the inbox
    # @param notification [NotifyPattern] The notification object
    # @param inbox_url [String, nil] The HTTP URI to send the notification to
    # @param validate [Boolean] Whether to validate the notification before sending
    # @return [NotifyResponse] Response from the server
    # @raise [NotifyException] if sending fails or response is unexpected
    def send(notification, inbox_url = nil, validate: true)
      inbox_url ||= @inbox_url
      inbox_url ||= notification.target.inbox
      raise NotifyException, "No inbox URL provided" unless inbox_url

      if validate && !notification.valid?
        raise NotifyException, "Attempting to send invalid notification"
      end

      headers = {
        "Content-Type" => 'application/ld+json;profile="https://www.w3.org/ns/activitystreams"'
      }

      resp = @http.post(inbox_url, notification.to_jsonld.to_json, headers)

      case resp.status_code
      when 201
        NotifyResponse.new(NotifyResponse::CREATED, resp.header("Location"))
      when 202
        NotifyResponse.new(NotifyResponse::ACCEPTED)
      else
        raise NotifyException, "Unexpected response: #{resp.status_code}"
      end
    end
  end
end