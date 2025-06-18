# frozen_string_literal: true

require 'net/http'
require 'uri'

module Coarnotify
  # HTTP layer interface and default implementation using Net::HTTP
  module Http
    # Interface for the HTTP layer
    #
    # This defines the methods which need to be implemented in order for the client to fully operate
    class HttpLayer
      # Make an HTTP POST request to the supplied URL with the given body data, and headers
      #
      # args and kwargs can be used to pass implementation-specific parameters
      #
      # @param url [String] the request URL
      # @param data [String] the body data
      # @param headers [Hash] HTTP headers as a hash to include in the request
      # @param args [Array] argument list to pass on to the implementation
      # @param kwargs [Hash] keyword arguments to pass on to the implementation
      # @return [HttpResponse] the HTTP response
      def post(url, data, headers = {}, *args, **kwargs)
        raise NotImplementedError
      end

      # Make an HTTP GET request to the supplied URL with the given headers
      #
      # args and kwargs can be used to pass implementation-specific parameters
      #
      # @param url [String] the request URL
      # @param headers [Hash] HTTP headers as a hash to include in the request
      # @param args [Array] argument list to pass on to the implementation
      # @param kwargs [Hash] keyword arguments to pass on to the implementation
      # @return [HttpResponse] the HTTP response
      def get(url, headers = {}, *args, **kwargs)
        raise NotImplementedError
      end
    end

    # Interface for the HTTP response object
    #
    # This defines the methods which need to be implemented in order for the client to fully operate
    class HttpResponse
      # Get the value of a header from the response
      #
      # @param header_name [String] the name of the header
      # @return [String] the header value
      def header(header_name)
        raise NotImplementedError
      end

      # Get the status code of the response
      #
      # @return [Integer] the status code
      def status_code
        raise NotImplementedError
      end
    end

    #######################################
    ## Implementations using Net::HTTP

    # Implementation of the HTTP layer using Net::HTTP. This is the default implementation
    # used when no other implementation is supplied
    class NetHttpLayer < HttpLayer
      # Make an HTTP POST request to the supplied URL with the given body data, and headers
      #
      # args and kwargs can be used to pass additional parameters to the Net::HTTP request,
      # such as authentication credentials, etc.
      #
      # @param url [String] the request URL
      # @param data [String] the body data
      # @param headers [Hash] HTTP headers as a hash to include in the request
      # @param args [Array] argument list (unused in this implementation)
      # @param kwargs [Hash] keyword arguments (unused in this implementation)
      # @return [NetHttpResponse] the HTTP response
      def post(url, data, headers = {}, *args, **kwargs)
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')

        request = Net::HTTP::Post.new(uri.request_uri)
        headers.each { |key, value| request[key] = value }
        request.body = data

        response = http.request(request)
        NetHttpResponse.new(response)
      end

      # Make an HTTP GET request to the supplied URL with the given headers
      #
      # args and kwargs can be used to pass additional parameters to the Net::HTTP request,
      # such as authentication credentials, etc.
      #
      # @param url [String] the request URL
      # @param headers [Hash] HTTP headers as a hash to include in the request
      # @param args [Array] argument list (unused in this implementation)
      # @param kwargs [Hash] keyword arguments (unused in this implementation)
      # @return [NetHttpResponse] the HTTP response
      def get(url, headers = {}, *args, **kwargs)
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')

        request = Net::HTTP::Get.new(uri.request_uri)
        headers.each { |key, value| request[key] = value }

        response = http.request(request)
        NetHttpResponse.new(response)
      end
    end

    # Implementation of the HTTP response object using Net::HTTP
    #
    # This wraps the Net::HTTP response object and provides the interface required by the client
    class NetHttpResponse < HttpResponse
      # Construct the object as a wrapper around the original Net::HTTP response object
      #
      # @param resp [Net::HTTPResponse] response object from Net::HTTP
      def initialize(resp)
        @resp = resp
      end

      # Get the value of a header from the response
      #
      # @param header_name [String] the name of the header
      # @return [String] the header value
      def header(header_name)
        @resp[header_name]
      end

      # Get the status code of the response
      #
      # @return [Integer] the status code
      def status_code
        @resp.code.to_i
      end

      # Get the original Net::HTTP response object
      #
      # @return [Net::HTTPResponse] the original response object
      def net_http_response
        @resp
      end
    end
  end
end
