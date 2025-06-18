# frozen_string_literal: true

require 'json'
require_relative 'factory'

module Coarnotify
  # Supporting classes for COAR Notify server implementations
  module Server
    # An object representing the response from a COAR Notify server.
    #
    # Server implementations should construct and return this object with the appropriate properties
    # when implementing the COARNotifyServiceBinding#notification_received binding
    class COARNotifyReceipt
      # The status code for a created resource
      CREATED = 201

      # The status code for an accepted request
      ACCEPTED = 202

      attr_reader :status, :location

      # Construct a new COARNotifyReceipt object with the status code and location URL (optional)
      #
      # @param status [Integer] the HTTP status code, should be one of the constants CREATED (201) or ACCEPTED (202)
      # @param location [String, nil] the HTTP URI for the resource that was created (if present)
      def initialize(status, location = nil)
        @status = status
        @location = location
      end
    end

    # Interface for implementing a COAR Notify server binding.
    #
    # Server implementation should extend this class and implement the notification_received method
    #
    # That method will receive a NotifyPattern object, which will be one of the known types
    # and should return a COARNotifyReceipt object with the appropriate status code and location URL
    class COARNotifyServiceBinding
      # Process the receipt of the given notification, and respond with an appropriate receipt object
      #
      # @param notification [Core::Notify::NotifyPattern] the notification object received
      # @return [COARNotifyReceipt] the receipt object to send back to the client
      def notification_received(notification)
        raise NotImplementedError
      end
    end

    # An exception class for server errors in the COAR Notify server implementation.
    #
    # The web layer of your server implementation should be able to intercept this from the
    # COARNotifyServer#receive method and return the appropriate HTTP status code and message to the
    # user in its standard way.
    class COARNotifyServerError < StandardError
      attr_reader :status, :message

      # Construct a new COARNotifyServerError with the given status code and message
      #
      # @param status [Integer] HTTP Status code to respond to the client with
      # @param msg [String] Message to send back to the client
      def initialize(status, msg)
        @status = status
        @message = msg
        super(msg)
      end
    end

    # The main entrypoint to the COAR Notify server implementation.
    #
    # The web layer of your application should pass the json/raw payload of any incoming notification to the
    # receive method, which will parse the payload and pass it to the COARNotifyServiceBinding#notification_received
    # method of your service implementation
    #
    # This object should be constructed with your service implementation passed to it, for example:
    #
    #   server = COARNotifyServer.new(MyServiceBinding.new)
    #   begin
    #     response = server.receive(request.body)
    #     # return response as JSON
    #   rescue COARNotifyServerError => e
    #     # return error with status e.status and message e.message
    #   end
    class COARNotifyServer
      # Construct a new COARNotifyServer with the given service implementation
      #
      # @param service_impl [COARNotifyServiceBinding] Your service implementation
      def initialize(service_impl)
        @service_impl = service_impl
      end

      # Receive an incoming notification as JSON, parse and validate (optional) and then pass to the
      # service implementation
      #
      # @param raw [Hash, String] The JSON representation of the data, either as a string or a hash
      # @param validate [Boolean] Whether to validate the notification before passing to the service implementation
      # @return [COARNotifyReceipt] The COARNotifyReceipt response from the service implementation
      def receive(raw, validate: true)
        raw = JSON.parse(raw) if raw.is_a?(String)

        obj = Factory::COARNotifyFactory.get_by_object(raw, validate_stream_on_construct: false)
        if validate
          begin
            obj.validate
          rescue ValidationError => e
            raise COARNotifyServerError.new(400, "Invalid notification")
          end
        end

        @service_impl.notification_received(obj)
      end
    end
  end
end
