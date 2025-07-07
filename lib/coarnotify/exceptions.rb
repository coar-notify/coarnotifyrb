# frozen_string_literal: true

module Coarnotify
  # Base class for all exceptions in the coarnotifyrb library
  class NotifyException < StandardError
  end

  # Exception class for validation errors.
  #
  # This class is designed to be thrown and caught and to collect validation errors
  # as it passes through the validation pipeline.
  #
  # For example an object validator may do something like this:
  #
  #   def validate
  #     ve = ValidationError.new
  #     ve.add_error(prop_name, "#{prop_name} is a required field")
  #     raise ve if ve.has_errors?
  #     true
  #   end
  #
  # If this is called by a subclass which is also validating, then this may be used
  # like this:
  #
  #   def validate
  #     ve = ValidationError.new
  #     begin
  #       super
  #     rescue ValidationError => superve
  #       ve = superve
  #     end
  #
  #     ve.add_error(prop_name, "#{prop_name} is a required field")
  #     raise ve if ve.has_errors?
  #     true
  #   end
  #
  # By the time the ValidationError is finally raised to the top, it will contain
  # all the validation errors from the various levels of validation that have been
  # performed.
  #
  # The errors are stored as a multi-level hash with the keys at the top level
  # being the fields in the data structure which have errors, and within the value
  # for each key there are two possible keys:
  #
  # * errors: an array of error messages for this field
  # * nested: a hash of further errors for nested fields
  #
  #   {
  #     "key1" => {
  #       "errors" => ["error1", "error2"],
  #       "nested" => {
  #         "key2" => {
  #           "errors" => ["error3"]
  #         }
  #       }
  #     }
  #   }
  class ValidationError < NotifyException
    attr_reader :errors

    # Create a new ValidationError with the given errors hash
    #
    # @param errors [Hash] The errors hash to initialize with
    def initialize(errors = {})
      super()
      @errors = errors
    end

    # Record an error on the supplied key with the message value
    #
    # @param key [String] the key for which an error is to be recorded
    # @param value [String] the error message
    def add_error(key, value)
      @errors[key] ||= { "errors" => [] }
      @errors[key]["errors"] << value
    end

    # Take an existing ValidationError and add it as a nested set of errors under the supplied key
    #
    # @param key [String] the key under which all the nested validation errors should go
    # @param subve [ValidationError] the existing ValidationError object
    def add_nested_errors(key, subve)
      @errors[key] ||= { "errors" => [] }
      @errors[key]["nested"] ||= {}

      subve.errors.each do |k, v|
        @errors[key]["nested"][k] = v
      end
    end

    # Are there any errors registered
    #
    # @return [Boolean] true if there are errors, false otherwise
    def has_errors?
      !@errors.empty?
    end

    # String representation of the errors
    #
    # @return [String] string representation of the errors hash
    def to_s
      @errors.to_s
    end
  end
end
