# frozen_string_literal: true

require 'json'
require_relative 'exceptions'
require_relative 'http'
require_relative 'core/notify'

module Coarnotify
  # This module contains all the client-specific code for sending notifications
  # to an inbox and receiving the responses it may return
  module Client
    # An object representing the response from a COAR Notify inbox.
    #
    # This contains the action that was carried out on the server:
    #
    # * CREATED - a new resource was created
    # * ACCEPTED - the request was accepted, but the resource was not yet created
    #
    # In the event that the resource is created, then there will also be a location
    # URL which will give you access to the resource
    class NotifyResponse
      CREATED = "created"
      ACCEPTED = "accepted"

      attr_reader :action, :location

      # Construct a new NotifyResponse object with the action (created or accepted) and the location URL (optional)
      #
      # @param action [String] The action which the server said it took
      # @param location [String, nil] The HTTP URI for the resource that was created (if present)
      def initialize(action, location = nil)
        @action = action
        @location = location
      end
    end

    # The COAR Notify Client, which is the mechanism through which you will interact with external inboxes.
    #
    # If you do not supply an inbox URL at construction you will
    # need to supply it via the inbox_url= setter, or when you send a notification
    class COARNotifyClient
      attr_accessor :inbox_url

      # Initialize the COAR Notify Client
      #
      # @param inbox_url [String, nil] HTTP URI of the inbox to communicate with by default
      # @param http_layer [Http::HttpLayer, nil] An implementation of the HttpLayer interface to use for sending HTTP requests
      def initialize(inbox_url: nil, http_layer: nil)
        @inbox_url = inbox_url
        @http = http_layer || Http::NetHttpLayer.new
      end

      # Send the given notification to the inbox. If no inbox URL is provided, the default inbox URL will be used.
      #
      # @param notification [Core::Notify::NotifyPattern] The notification object
      # @param inbox_url [String, nil] The HTTP URI to send the notification to
      # @param validate [Boolean] Whether to validate the notification before sending
      # @return [NotifyResponse] a NotifyResponse object representing the response from the server
      def send(notification, inbox_url: nil, validate: true)
        inbox_url ||= @inbox_url
        inbox_url ||= notification.target&.inbox
        
        raise ArgumentError, "No inbox URL provided at the client, method, or notification level" if inbox_url.nil?

        if validate
          begin
            notification.validate
          rescue ValidationError => e
            raise NotifyException, "Attempting to send invalid notification; to override set validate: false when calling this method"
          end
        end

        resp = @http.post(inbox_url,
                          JSON.generate(notification.to_jsonld),
                          { "Content-Type" => "application/ld+json;profile=\"https://www.w3.org/ns/activitystreams\"" })

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
end
