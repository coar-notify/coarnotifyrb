# This module provides validation functions for COAR Notify properties

module COARNotify
  module Validate
    REQUIRED_MESSAGE = "`%{x}` is a required field".freeze

    class Validator
      def initialize(rules)
        @rules = rules
      end

      def get(property, context = nil)
        default = @rules.dig(property, "default")
        return default if context.nil?

        specific = @rules.dig(property, "context", context, "default")
        specific || default
      end

      def rules
        @rules
      end

      def add_rules(new_rules)
        @rules = deep_merge(@rules, new_rules)
      end

      private

      def deep_merge(hash1, hash2)
        hash1.merge(hash2) do |key, old_val, new_val|
          if old_val.is_a?(Hash) && new_val.is_a?(Hash)
            deep_merge(old_val, new_val)
          else
            new_val
          end
        end
      end
    end

    # URI validation patterns
    URI_RE = /^(([^:\/?#]+):)?(\/\/([^\/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?/
    SCHEME = /^[a-zA-Z][a-zA-Z0-9+\-.]*$/
    IPV6 = /(?:^|(?<=\s))\[{0,1}(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))]{0,1}(?=\s|$)/

    HOSTPORT = /
      ^(?:(?:[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?\.)+(?:[A-Z]{2,6}\.?|[A-Z0-9-]{2,}\.?)| # domain
      localhost| # localhost
      \d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}| # ipv4
      (?:^|(?<=\s))(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))(?=\s|$)
      )(?::\d+)?$/ix # optional port

    MARK = "-_.!~*'()"
    UNRESERVED = "a-zA-Z0-9#{MARK}"
    PCHARS = "#{UNRESERVED}:@&=+$,%/"
    PATH = /^\/{0,1}[#{PCHARS}]*$/

    RESERVED = ";/?:@&=+$,"
    URIC = "#{RESERVED}#{UNRESERVED}%"
    FREE = /^[#{URIC}]+$/

    USERINFO = /^[#{UNRESERVED}%;:&=+$,]*$/

    def self.absolute_uri(obj, uri)
      m = URI_RE.match(uri)
      raise "Invalid URI" unless m

      # URI must be absolute, so requires a scheme
      raise "URI requires a scheme" unless m[2]

      scheme = m[2]
      authority = m[4]
      path = m[5]
      query = m[7]
      fragment = m[9]

      # Validate scheme
      raise "Invalid URI scheme `#{scheme}`" if scheme && !SCHEME.match(scheme)

      if authority
        userinfo, hostport = authority.split("@", 2) if authority.include?("@")
        hostport ||= authority

        if userinfo && !USERINFO.match(userinfo)
          raise "Invalid URI authority `#{authority}`"
        end

        # Handle IPv6 addresses
        if hostport.start_with?("[")
          port_separator = hostport.rindex("]:")
          if port_separator
            port = hostport[port_separator+2..-1]
            host = hostport[1...port_separator]
          else
            host = hostport[1...-1]
          end
          raise "Invalid URI authority `#{authority}`" unless IPV6.match(host)
          if port
            begin
              Integer(port)
            rescue ArgumentError
              raise "Invalid URI port `#{port}`"
            end
          end
        else
          raise "Invalid URI authority `#{authority}`" unless HOSTPORT.match(hostport)
        end
      end

      raise "Invalid URI path `#{path}`" if path && !PATH.match(path)
      raise "Invalid URI query `#{query}`" if query && !FREE.match(query)
      raise "Invalid URI fragment `#{fragment}`" if fragment && !FREE.match(fragment)

      true
    end

    def self.url(obj, url)
      absolute_uri(obj, url)
      uri = URI.parse(url)
      raise "URL scheme must be http or https" unless ["http", "https"].include?(uri.scheme)
      raise "Invalid URL" if uri.host.nil? || uri.host.empty?
      true
    rescue URI::InvalidURIError
      raise "Invalid URL"
    end

    def self.one_of(values)
      ->(obj, x) do
        unless values.include?(x)
          raise "`#{x}` is not one of the valid values: #{values}"
        end
        true
      end
    end

    def self.at_least_one_of(values)
      ->(obj, x) do
        x = [x] unless x.is_a?(Array)
        return true if x.any? { |v| values.include?(v) }
        raise "`#{x}` is not one of the valid values: #{values}"
      end
    end

    def self.contains(value)
      values = Array(value).to_set

      ->(obj, x) do
        x = Array(x).to_set
        return true if values.subset?(x)
        raise "`#{x}` does not contain the required value(s): #{values.to_a}"
      end
    end

    def self.type_checker(obj, value)
      if obj.respond_to?(:allowed_types) && !obj.allowed_types.empty?
        one_of(obj.allowed_types).call(obj, value)
      elsif obj.respond_to?(:type)
        contains(obj.type).call(obj, value)
      end
      true
    end
  end
end