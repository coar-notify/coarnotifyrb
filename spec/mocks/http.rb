# frozen_string_literal: true

module Mocks
  # Mock HTTP layer for testing
  class MockHttpLayer < Coarnotify::Http::HttpLayer
    attr_reader :status_code, :location

    def initialize(status_code: 200, location: nil)
      @status_code = status_code
      @location = location
    end

    def post(url, data, headers = {}, *args, **kwargs)
      MockHttpResponse.new(status_code: @status_code, location: @location)
    end

    def get(url, headers = {}, *args, **kwargs)
      raise NotImplementedError, "GET not implemented in mock"
    end
  end

  # Mock HTTP response for testing
  class MockHttpResponse < Coarnotify::Http::HttpResponse
    attr_reader :status_code, :location

    def initialize(status_code: 200, location: nil)
      @status_code = status_code
      @location = location
    end

    def header(header_name)
      case header_name.downcase
      when "location"
        @location
      else
        nil
      end
    end

    def status_code
      @status_code
    end
  end
end
