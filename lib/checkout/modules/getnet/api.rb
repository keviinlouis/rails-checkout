module Checkout
  module Getnet
    class Api
      include ::Checkout::Getnet::CreditCard

      SANDBOX_URL = 'https://api-sandbox.getnet.com.br'.freeze
      PRODUCTION_URL = 'https://api.getnet.com.br'.freeze

      def initialize(access_token = nil)
        @auth = Checkout::Getnet::Auth.new access_token
      end

      def get(url, headers = {})
        request(:get, url, data, headers)
      end

      def post(url, payload, headers = {})
        request(:post, url, payload, headers)
      end

      def put(url, payload, headers = {})
        request(:put, url, payload, headers)
      end

      def delete(url, headers = {})
        request(:delete, url, data, headers)
      end

      def access_token
        payload = { scope: 'oob', grant_type: 'client_credentials' }
        headers = {
          authorization: authorization_header,
          content_type: 'application/x-www-form-urlencoded'
        }
        post('auth/oauth/v2/token', payload, headers)
      end

      def update_access_token(access_token)
        @auth.update_access_token(access_token)
      end

      private

      def request(method, url, payload, headers = {}, parse_body = true)
        response = RestClient::Request.execute(
          method: method,
          url: build_url(url),
          payload: payload,
          headers: base_headers.merge(headers)
        )

        return response unless parse_body

        JSON.parse response.body
      rescue RestClient::Exception => e
        binding.pry
      end

      def build_url(url)
        base_url = @auth.sandbox? ? SANDBOX_URL : PRODUCTION_URL
        "#{base_url}/#{url}"
      end

      def base_headers
        {
          authorization: access_token_header,
          content_type: 'application/json; charset=utf-8'
        }
      end

      def authorization_header
        tokens = "#{@auth.client_id}:#{@auth.client_secret}"
        %(Basic #{Base64.strict_encode64(tokens)})
      end

      def access_token_header
        %(Bearer #{@auth.access_token})
      end
    end
  end
end