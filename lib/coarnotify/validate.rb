# frozen_string_literal: true

require 'uri'
require 'set'

module Coarnotify
  # This module provides a set of validation functions that can be used to validate properties on objects.
  # It also contains a Validator class which is used to wrap the protocol-wide validation rules which
  # are shared across all objects.
  module Validate
    REQUIRED_MESSAGE = "`%s` is a required field"

    # A wrapper around a set of validation rules which can be used to select the appropriate validator
    # in a given context.
    #
    # The validation rules are structured as follows:
    #
    #   {
    #     "<property>" => {
    #       "default" => default_validator_function,
    #       "context" => {
    #         "<context>" => {
    #           "default" => default_validator_function
    #         }
    #       }
    #     }
    #   }
    #
    # Here the <property> key is the name of the property being validated, which may be a string (the property name)
    # or an array of strings (the property name and the namespace for the property name).
    #
    # If a context is provided, then if the top level property is being validated, and it appears inside a field
    # present in the context then the default validator at the top level is overridden by the default validator
    # in the context.
    class Validator
      attr_reader :rules

      # Create a new validator with the given rules
      #
      # @param rules [Hash] The rules to use for validation
      def initialize(rules)
        @rules = rules
      end

      # Get the validation function for the given property in the given context
      #
      # @param property [String, Array] the property to get the validation function for
      # @param context [String, Array] the context in which the property is being validated
      # @return [Proc] a function which can be used to validate the property
      def get(property, context = nil)
        default = @rules.dig(property, "default")
        if context
          # FIXME: down the line this might need to become recursive
          specific = @rules.dig(property, "context", context, "default")
          return specific if specific
        end
        default
      end

      # Add additional rules to this validator
      #
      # @param rules [Hash] additional rules to merge
      def add_rules(rules)
        @rules = merge_dicts_recursive(@rules, rules)
      end

      private

      def merge_dicts_recursive(dict1, dict2)
        merged = dict1.dup
        dict2.each do |key, value|
          if merged.key?(key) && merged[key].is_a?(Hash) && value.is_a?(Hash)
            merged[key] = merge_dicts_recursive(merged[key], value)
          else
            merged[key] = value
          end
        end
        merged
      end
    end

    # URI validation regular expressions
    URI_RE = /^(([^:\/?#]+):)?(\/\/([^\/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?/
    SCHEME_RE = /^[a-zA-Z][a-zA-Z0-9+\-.]*$/
    IPV6_RE = /(?:^|(?<=\s))\[{0,1}(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))\]{0,1}(?=\s|$)/

    HOSTPORT_RE = /^(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+(?:[A-Z]{2,6}\.?|[A-Z0-9-]{2,}\.?)|localhost|\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}|(?:^|(?<=\s))(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))(?=\s|$))(?::\d+)?$/i

    MARK = "\\-_.!~*'()"
    UNRESERVED = "a-zA-Z0-9#{MARK}"
    PCHARS = "#{UNRESERVED}:@&=+$,%/;"
    PATH_RE = /^#{Regexp.escape('/')}?[#{PCHARS}]*$/

    RESERVED = ";/?:@&=+$,"
    URIC = "#{RESERVED}#{UNRESERVED}%"
    FREE_RE = /^[#{URIC}]+$/

    USERINFO_RE = /^[#{UNRESERVED}%;:&=+$,]*$/

    # Validate that the given string is an absolute URI
    #
    # @param obj [Object] The Notify object to which the property being validated belongs
    # @param uri [String] The string that claims to be an absolute URI
    # @return [Boolean] true if the URI is valid, otherwise ArgumentError is raised
    def self.absolute_uri(obj, uri)
      m = URI_RE.match(uri)
      raise ArgumentError, "Invalid URI" unless m

      # URI must be absolute, so requires a scheme
      raise ArgumentError, "URI requires a scheme (this may be a relative rather than absolute URI)" unless m[2]

      scheme = m[2]
      authority = m[4]
      path = m[5]
      query = m[7]
      fragment = m[9]

      # scheme must be alpha followed by alphanum or +, -, or .
      if scheme
        raise ArgumentError, "Invalid URI scheme `#{scheme}`" unless SCHEME_RE.match?(scheme)
      end

      if authority
        userinfo = nil
        hostport = authority
        if authority.include?("@")
          userinfo, hostport = authority.split("@", 2)
        end
        if userinfo
          raise ArgumentError, "Invalid URI authority `#{authority}`" unless USERINFO_RE.match?(userinfo)
        end
        # determine if the domain is ipv6
        if hostport.start_with?("[")    # ipv6 with an optional port
          port_separator = hostport.rindex("]:")
          port = nil
          if port_separator
            port = hostport[port_separator+2..-1]
            host = hostport[1...port_separator]
          else
            host = hostport[1..-2]
          end
          raise ArgumentError, "Invalid URI authority `#{authority}`" unless IPV6_RE.match?(host)
          if port
            begin
              Integer(port)
            rescue ArgumentError
              raise ArgumentError, "Invalid URI port `#{port}`"
            end
          end
        else
          raise ArgumentError, "Invalid URI authority `#{authority}`" unless HOSTPORT_RE.match?(hostport)
        end
      end

      if path
        raise ArgumentError, "Invalid URI path `#{path}`" unless PATH_RE.match?(path)
      end

      if query
        raise ArgumentError, "Invalid URI query `#{query}`" unless FREE_RE.match?(query)
      end

      if fragment
        raise ArgumentError, "Invalid URI fragment `#{fragment}`" unless FREE_RE.match?(fragment)
      end

      true
    end

    # Validate that the given string is an absolute HTTP URI (i.e. a URL)
    #
    # @param obj [Object] The Notify object to which the property being validated belongs
    # @param url [String] The string that claims to be an HTTP URI
    # @return [Boolean] true if the URI is valid, otherwise ArgumentError is raised
    def self.url(obj, url)
      absolute_uri(obj, url)
      o = URI.parse(url)
      raise ArgumentError, "URL scheme must be http or https" unless %w[http https].include?(o.scheme)
      raise ArgumentError, "Does not appear to be a valid URL" if o.host.nil? || o.host.empty?
      true
    end

    # Closure that returns a validation function that checks that the value is one of the given values
    #
    # @param values [Array<String>] The list of values to choose from
    # @return [Proc] a validation function
    def self.one_of(values)
      proc do |obj, x|
        unless values.include?(x)
          raise ArgumentError, "`#{x}` is not one of the valid values: #{values}"
        end
        true
      end
    end

    # Closure that returns a validation function that checks that a list of values contains at least one
    # of the given values
    #
    # @param values [Array<String>] The list of values to choose from
    # @return [Proc] a validation function
    def self.at_least_one_of(values)
      proc do |obj, x|
        x = [x] unless x.is_a?(Array)

        found = x.any? { |entry| values.include?(entry) }

        unless found
          # if we don't find one of the document values in the list of "at least one of" values,
          # raise an exception
          raise ArgumentError, "`#{x}` is not one of the valid values: #{values}"
        end

        true
      end
    end

    # Closure that returns a validation function that checks the provided values contain the required value
    #
    # @param value [String, Array<String>] The value(s) that must be present
    # @return [Proc] a validation function
    def self.contains(value)
      values = value.is_a?(Array) ? value : [value]
      values_set = values.to_set

      proc do |obj, x|
        x = [x] unless x.is_a?(Array)
        x_set = x.to_set

        intersection = x_set & values_set
        unless intersection == values_set
          raise ArgumentError, "`#{x}` does not contain the required value(s): #{values}"
        end
        true
      end
    end

    # Validate that the given value is of the correct type for the object
    #
    # @param obj [Object] the notify object being validated
    # @param value [String, Array<String>] the type being validated
    # @return [Boolean] true if the type is valid, otherwise ArgumentError is raised
    def self.type_checker(obj, value)
      if obj.respond_to?(:allowed_types)
        allowed = obj.allowed_types
        return true if allowed.empty?
        validator = one_of(allowed)
        validator.call(obj, value)
      elsif obj.respond_to?(:type_constant)
        ty = obj.type_constant
        validator = contains(ty)
        validator.call(obj, value)
      end
      true
    end
  end
end
