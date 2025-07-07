# frozen_string_literal: true

require 'json'

# This is the base of the coarnotifyrb module.
#
# In here you will find
# a full set of model objects for all the Notify Patterns documented in
# https://coar-notify.net/specification/1.0.1/
#
# You will also find a client library that will allow you to send notifications
# to an inbox, and a server library that will allow you to write a service
# binding to your own systems to receive notifications via an inbox.
#
# There are also unit tests demonstrating the various features of the system,
# integration tests which can be run against a remote inbox, and a
# stand-alone inbox you can use for local testing.

require_relative 'coarnotify/version'
require_relative 'coarnotify/exceptions'
require_relative 'coarnotify/validate'
require_relative 'coarnotify/core/activity_streams2'
require_relative 'coarnotify/core/notify'
require_relative 'coarnotify/http'
require_relative 'coarnotify/patterns/accept'
require_relative 'coarnotify/patterns/announce_endorsement'
require_relative 'coarnotify/patterns/announce_relationship'
require_relative 'coarnotify/patterns/announce_review'
require_relative 'coarnotify/patterns/announce_service_result'
require_relative 'coarnotify/patterns/reject'
require_relative 'coarnotify/patterns/request_endorsement'
require_relative 'coarnotify/patterns/request_review'
require_relative 'coarnotify/patterns/tentatively_accept'
require_relative 'coarnotify/patterns/tentatively_reject'
require_relative 'coarnotify/patterns/undo_offer'
require_relative 'coarnotify/patterns/unprocessable_notification'
require_relative 'coarnotify/factory'
require_relative 'coarnotify/client'
require_relative 'coarnotify/server'

# Main module for the COAR Notify Ruby implementation
module Coarnotify
  # Convenience method to create a new COAR Notify client
  #
  # @param inbox_url [String, nil] HTTP URI of the inbox to communicate with by default
  # @param http_layer [Http::HttpLayer, nil] An implementation of the HttpLayer interface
  # @return [Client::COARNotifyClient] a new client instance
  def self.client(inbox_url: nil, http_layer: nil)
    Client::COARNotifyClient.new(inbox_url: inbox_url, http_layer: http_layer)
  end

  # Convenience method to create a new COAR Notify server
  #
  # @param service_impl [Server::COARNotifyServiceBinding] Your service implementation
  # @return [Server::COARNotifyServer] a new server instance
  def self.server(service_impl)
    Server::COARNotifyServer.new(service_impl)
  end

  # Convenience method to create a pattern from a hash
  #
  # @param data [Hash] The raw stream data to parse and instantiate around
  # @param options [Hash] any options to pass to the object constructor
  # @return [Core::Notify::NotifyPattern] A NotifyPattern of the correct type
  def self.from_hash(data, **options)
    Factory::COARNotifyFactory.get_by_object(data, **options)
  end

  # Convenience method to create a pattern from JSON
  #
  # @param json [String] The JSON string to parse and instantiate around
  # @param options [Hash] any options to pass to the object constructor
  # @return [Core::Notify::NotifyPattern] A NotifyPattern of the correct type
  def self.from_json(json, **options)
    data = JSON.parse(json)
    from_hash(data, **options)
  end
end
