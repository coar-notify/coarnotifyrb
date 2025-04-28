# Factory for producing the correct model based on the type or data within a payload
require_relative 'core/activitystreams2'
require_relative 'core/notify'
require_relative 'patterns'

module COARNotify
  class Factory
    # The list of model classes recognised by this factory
    MODELS = [
      Accept,
      AnnounceEndorsement,
      AnnounceRelationship,
      AnnounceReview,
      AnnounceServiceResult,
      Reject,
      RequestEndorsement,
      RequestReview,
      TentativelyAccept,
      TentativelyReject,
      UnprocessableNotification,
      UndoOffer
    ].freeze

    # Get the model class based on the supplied types
    # @param incoming_types [String, Array<String>] a single type or array of types
    # @return [Class, nil] A class representing the best fit for the supplied types
    def self.get_by_types(incoming_types)
      incoming_types = Array(incoming_types) unless incoming_types.is_a?(Array)
      
      candidate = nil
      candidate_fit = nil

      MODELS.each do |model|
        document_types = model::TYPE
        document_types = Array(document_types) unless document_types.is_a?(Array)
        
        if (document_types - incoming_types).empty?
          fit = incoming_types.size - document_types.size
          
          if fit == 0
            return model
          elsif candidate_fit.nil? || fit.abs < candidate_fit.abs
            candidate = model
            candidate_fit = fit
          end
        end
      end

      candidate
    end

    # Get an instance of a model based on the data provided
    # @param data [Hash] The raw stream data to parse
    # @param args [Array] args to pass to the object constructor
    # @param kwargs [Hash] kwargs to pass to the object constructor
    # @return [NotifyPattern] A NotifyPattern of the correct type
    # @raise [NotifyException] if no matching model is found
    def self.get_by_object(data, *args, **kwargs)
      stream = ActivityStream.new(data)
      types = stream.get_property(Properties::TYPE)
      
      raise NotifyException, "No type found in object" unless types

      klass = get_by_types(types)
      raise NotifyException, "No matching model found for types: #{types}" unless klass

      klass.new(data, *args, **kwargs)
    end

    # Register a new model class with the factory
    # @param model [Class] The model class to register
    def self.register(model)
      existing = get_by_types(model::TYPE)
      MODELS.delete(existing) if existing
      MODELS << model
    end
  end
end