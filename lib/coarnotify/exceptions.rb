module COARNotify
    class NotifyException < StandardError
      # Base class for all exceptions in the coarnotify library
    end
  
    class ValidationError < NotifyException
      # Exception class for validation errors.
      #
      # @param errors [Hash, nil] a hash of errors to construct the exception around
      #
      # The errors are stored as a multi-level hash with the keys at the top level
      # being the fields in the data structure which have errors, and within the value
      # for each key there are two possible keys:
      #
      # * errors: an array of error messages for this field
      # * nested: a hash of further errors for nested fields
      #
      # Example:
      # {
      #   "key1" => {
      #     "errors" => ["error1", "error2"],
      #     "nested" => {
      #       "key2" => {
      #         "errors" => ["error3"]
      #       }
      #     }
      #   }
      # }
  
      attr_reader :errors
  
      def initialize(errors = nil)
        super()
        @errors = errors || {}
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
  
      # Are there any errors registered?
      #
      # @return [Boolean] true if errors exist
      def has_errors?
        !@errors.empty?
      end
  
      def to_s
        @errors.to_s
      end
    end
  end