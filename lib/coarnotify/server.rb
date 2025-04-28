# Supporting classes for COAR Notify server implementations
require 'json'
require_relative 'factory'
require_relative 'core/notify'

module COARNotify
  class Receipt
    # An object representing the response from a COAR Notify server.
    # Server implementations should construct and return this object when implementing
    # the notification_received binding
    
    CREATED = 201 # The status code for a created resource
    ACCEPTED = 202 # The status code for an accepted request

    attr_reader :status, :location

    # Construct a new Receipt object
    # @param status [Integer] HTTP status code (201 or 202)
    # @param location [String, nil] HTTP URI for the created resource
    def initialize(status, location = nil)
      @status = status
      @location = location
    end
  end

  module ServiceBinding
    # Interface for implementing a COAR Notify server binding.
    # Server implementations should extend this module and implement notification_received
    
    # Process the receipt of a notification
    # @param notification [NotifyPattern] the received notification
    # @return [Receipt] response to send back to client
    def notification_received(notification)
      raise NotImplementedError, "#{self.class} must implement notification_received"
    end
  end

  class ServerError < StandardError
    # Exception class for server errors in COAR Notify server implementation
    
    attr_reader :status, :message

    # Construct a new ServerError
    # @param status [Integer] HTTP status code for the error
    # @param msg [String] Error message to send back to client
    def initialize(status, msg)
      @status = status
      @message = msg
      super(msg)
    end
  end

  class Server
    # Main entrypoint to the COAR Notify server implementation
    
    # @param service_impl [ServiceBinding] Your service implementation
    def initialize(service_impl)
      @service_impl = service_impl
    end

    # Receive an incoming notification
    # @param raw [Hash, String] JSON representation of the data
    # @param validate [Boolean] Whether to validate the notification
    # @return [Receipt] Response from the service implementation
    # @raise [ServerError] if validation fails or other error occurs
    def receive(raw, validate: true)
      data = raw.is_a?(String) ? JSON.parse(raw) : raw
      obj = COARNotifyFactory.get_by_object(data)

      if validate && !obj.valid?
        raise ServerError.new(400, "Invalid notification")
      end

      @service_impl.notification_received(obj)
    end
  end
end