require 'uri'

# Module to provide validation functions and a Validator class
module Validate
  REQUIRED_MESSAGE = "`%{x}` is a required field"

  class Validator
    # @param rules [Hash] A hash containing validation rules
    def initialize(rules)
      @rules = rules
    end

    # @param property [String, Array<String>] The property to get the validation function for
    # @param context [String, Array<String>, nil] The context in which the property is being validated
    # @return [Proc, nil] A callable validation function or nil if not found
    def get(property, context = nil)
      default = @rules.dig(property, :default)
      if context
        specific = @rules.dig(property, :context, context, :default)
        return specific if specific
      end
      default
    end

    # @return [Hash] The ruleset
    def rules
      @rules
    end

    # @param new_rules [Hash] New rules to merge into the existing ruleset
    def add_rules(new_rules)
      @rules = merge_dicts_recursive(@rules, new_rules)
    end

    private

    # @param hash1 [Hash] The first hash to merge
    # @param hash2 [Hash] The second hash to merge
    # @return [Hash] The merged hash
    def merge_dicts_recursive(hash1, hash2)
      hash1.merge(hash2) do |key, old_val, new_val|
        old_val.is_a?(Hash) && new_val.is_a?(Hash) ? merge_dicts_recursive(old_val, new_val) : new_val
      end
    end
  end

  #############################################
  ## URI validator

  # @param obj [Object] The object being validated
  # @param uri [String] The URI to validate
  # @return [Boolean] True if the URI is valid, otherwise raises an error
  def self.absolute_uri(obj, uri)
    parsed_uri = URI.parse(uri)
    raise ArgumentError, "Invalid URI" unless parsed_uri.absolute?

    # Validate scheme
    scheme = parsed_uri.scheme
    raise ArgumentError, "Invalid URI scheme `#{scheme}`" unless scheme =~ /^[a-zA-Z][a-zA-Z0-9+\-.]*$/

    # Validate authority
    authority = parsed_uri.host
    raise ArgumentError, "Invalid URI authority `#{authority}`" if authority.nil? || authority.empty?

    # Validate path, query, and fragment
    # ...existing code for path, query, and fragment validation...
    true
  rescue URI::InvalidURIError
    raise ArgumentError, "Invalid URI"
  end

  # @param obj [Object] The object being validated
  # @param url [String] The URL to validate
  # @return [Boolean] True if the URL is valid, otherwise raises an error
  def self.url(obj, url)
    absolute_uri(obj, url)
    parsed_url = URI.parse(url)
    raise ArgumentError, "URL scheme must be http or https" unless %w[http https].include?(parsed_url.scheme)
    raise ArgumentError, "Does not appear to be a valid URL" if parsed_url.host.nil? || parsed_url.host.empty?
    true
  end

  # @param values [Array<String>] The list of valid values
  # @return [Proc] A validation function
  def self.one_of(values)
    lambda do |obj, x|
      raise ArgumentError, "`#{x}` is not one of the valid values: #{values}" unless values.include?(x)
      true
    end
  end

  # @param values [Array<String>] The list of valid values
  # @return [Proc] A validation function
  def self.at_least_one_of(values)
    lambda do |obj, x|
      x = [x] unless x.is_a?(Array)
      return true if (x & values).any?

      raise ArgumentError, "`#{x}` does not contain at least one of the valid values: #{values}"
    end
  end

  # @param value [String] The required value
  # @return [Proc] A validation function
  def self.contains(value)
    values = [value].flatten.to_set
    lambda do |obj, x|
      x = [x].flatten.to_set
      raise ArgumentError, "`#{x}` does not contain the required value(s): #{values}" unless values.subset?(x)
      true
    end
  end

  # @param obj [Object] The object being validated
  # @param value [Object] The value to validate
  # @return [Boolean] True if the type is valid, otherwise raises an error
  def self.type_checker(obj, value)
    if obj.respond_to?(:ALLOWED_TYPES) && !obj.ALLOWED_TYPES.empty?
      validator = one_of(obj.ALLOWED_TYPES)
      validator.call(obj, value)
    elsif obj.respond_to?(:TYPE)
      validator = contains(obj.TYPE)
      validator.call(obj, value)
    end
    true
  end
end
