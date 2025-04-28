# HTTP layer interface and default implementation using Net::HTTP
require 'net/http'
require 'uri'

module COARNotify
  module HttpLayer
    # Interface for the HTTP layer
    def post(url, data, headers = {})
      raise NotImplementedError, "#{self.class} must implement post method"
    end

    def get(url, headers = {})
      raise NotImplementedError, "#{self.class} must implement get method"
    end
  end

  module HttpResponse
    # Interface for HTTP responses
    def header(name)
      raise NotImplementedError, "#{self.class} must implement header method"
    end

    def status_code
      raise NotImplementedError, "#{self.class} must implement status_code method"
    end
  end

  # Default implementation using Net::HTTP
  class NetHttpLayer
    include HttpLayer

    def post(url, data, headers = {})
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'

      request = Net::HTTP::Post.new(uri.request_uri)
      headers.each { |k, v| request[k] = v }
      request.body = data

      response = http.request(request)
      NetHttpResponse.new(response)
    end

    def get(url, headers = {})
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'

      request = Net::HTTP::Get.new(uri.request_uri)
      headers.each { |k, v| request[k] = v }

      response = http.request(request)
      NetHttpResponse.new(response)
    end
  end

  class NetHttpResponse
    include HttpResponse

    def initialize(response)
      @response = response
    end

    def header(name)
      @response[name]
    end

    def status_code
      @response.code.to_i
    end

    # Additional access to raw response
    def raw_response
      @response
    end
  end
end