# frozen_string_literal: true

require 'set'
require_relative 'core/activity_streams2'
require_relative 'core/notify'
require_relative 'patterns/accept'
require_relative 'patterns/announce_endorsement'
require_relative 'patterns/announce_relationship'
require_relative 'patterns/announce_review'
require_relative 'patterns/announce_service_result'
require_relative 'patterns/reject'
require_relative 'patterns/request_endorsement'
require_relative 'patterns/request_review'
require_relative 'patterns/tentatively_accept'
require_relative 'patterns/tentatively_reject'
require_relative 'patterns/unprocessable_notification'
require_relative 'patterns/undo_offer'
require_relative 'exceptions'

module Coarnotify
  # Factory for producing the correct model based on the type or data within a payload
  module Factory
    # Factory for producing the correct model based on the type or data within a payload
    class COARNotifyFactory
      # The list of model classes recognised by this factory
      MODELS = [
        Patterns::Accept,
        Patterns::AnnounceEndorsement,
        Patterns::AnnounceRelationship,
        Patterns::AnnounceReview,
        Patterns::AnnounceServiceResult,
        Patterns::Reject,
        Patterns::RequestEndorsement,
        Patterns::RequestReview,
        Patterns::TentativelyAccept,
        Patterns::TentativelyReject,
        Patterns::UnprocessableNotification,
        Patterns::UndoOffer
      ]

      # Get the model class based on the supplied types. The returned value is the class, not an instance.
      #
      # This is achieved by inspecting all of the known types in MODELS, and performing the following
      # calculation:
      #
      # 1. If the supplied types are a subset of the model types, then this is a candidate, keep a reference to it
      # 2. If the candidate fit is exact (supplied types and model types are the same), return the class
      # 3. If the class is a better fit than the last candidate, update the candidate. If the fit is exact, return the class
      # 4. Once we have run out of models to check, return the best candidate (or nil if none found)
      #
      # @param incoming_types [String, Array<String>] a single type or array of types
      # @return [Class, nil] A class representing the best fit for the supplied types, or nil if no match
      def self.get_by_types(incoming_types)
        incoming_types = [incoming_types] unless incoming_types.is_a?(Array)

        candidate = nil
        candidate_fit = nil

        MODELS.each do |m|
          document_types = m.type_constant
          document_types = [document_types] unless document_types.is_a?(Array)
          
          if document_types.to_set.subset?(incoming_types.to_set)
            if candidate_fit.nil?
              candidate = m
              candidate_fit = incoming_types.length - document_types.length
              return candidate if candidate_fit == 0
            else
              fit = incoming_types.length - document_types.length
              return m if fit == 0
              if fit.abs < candidate_fit.abs
                candidate = m
                candidate_fit = fit
              end
            end
          end
        end

        candidate
      end

      # Get an instance of a model based on the data provided.
      #
      # Internally this calls get_by_types to determine the class to instantiate, and then creates an instance of that
      # using the supplied options.
      #
      # If a model cannot be found that matches the data, a NotifyException is raised.
      #
      # @param data [Hash] The raw stream data to parse and instantiate around
      # @param options [Hash] any options to pass to the object constructor
      # @return [Core::Notify::NotifyPattern] A NotifyPattern of the correct type, wrapping the data
      def self.get_by_object(data, **options)
        stream = Core::ActivityStreams2::ActivityStream.new(data)

        types = stream.get_property(Core::ActivityStreams2::Properties::TYPE)
        raise NotifyException, "No type found in object" if types.nil?

        klazz = get_by_types(types)
        raise NotifyException, "No matching pattern found for types: #{types}" if klazz.nil?

        klazz.new(stream: data, **options)
      end

      # Register a new model with the factory
      #
      # @param model [Class] the model class to register
      def self.register(model)
        existing = get_by_types(model.type_constant)
        MODELS.delete(existing) if existing
        MODELS << model
      end
    end
  end
end
