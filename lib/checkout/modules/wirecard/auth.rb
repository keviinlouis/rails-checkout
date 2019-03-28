require 'moip2'

module Checkout
  module Wirecard
    class Auth
      attr_accessor :env

      WIRECARD_ENV = [:production, :development]

      def initialize(token_oauth = nil)
        @token = Checkout.configuration.wirecard[:token]
        @key = Checkout.configuration.wirecard[:key]
        @token_oauth = token_oauth
        @env = Checkout.configuration.wirecard[:env]

        validate
      end

      def get_client
        auth = is_oauth? ? get_oauth : get_auth_basic

        Moip2::Client.new(@env, auth)
      end

      def is_oauth?
        !@token_oauth.nil?
      end

      def is_sandbox?
        @env != :production
      end

      def get_oauth_token
        @token_oauth
      end

      def get_basic_token
        Base64.encode64("#{@token}:#{@key}").gsub("\n", '')
      end

      private

      def get_oauth
        Moip2::Auth::OAuth.new(@token_oauth)
      end

      def get_auth_basic
        Moip2::Auth::Basic.new(@token, @key)
      end

      def validate
        throw Checkout::Exception::EnvironmentNotFounded unless WIRECARD_ENV.include? @env

        throw Checkout::Exception::AuthNotFounded if (@token.nil? && @key.nil?) && @token_oauth.nil?
      end
    end
  end
end
