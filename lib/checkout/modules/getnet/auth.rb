module Checkout
  module Getnet
    class Auth
      attr_accessor :env
      attr_reader :client_id, :client_secret, :access_token

      GETNET_ENV = %i[production development].freeze

      def initialize(access_token = nil)
        if Checkout.configuration.getnet.nil?
          raise Checkout::Exception::AuthNotFounded
        end

        @client_id = Checkout.configuration.getnet[:client_id]
        @client_secret = Checkout.configuration.getnet[:client_secret]
        @env = Checkout.configuration.getnet[:env]

        @access_token = access_token

        validate
      end

      def sandbox?
        @env != :production
      end

      def update_access_token(access_token)
        @access_token = access_token
      end

      private

      def validate
        unless GETNET_ENV.include? @env
          raise Checkout::Exception::EnvironmentNotFounded
        end

        if (@client_id.nil? && @client_secret.nil?) && @access_token.nil?
          raise Checkout::Exception::AuthNotFounded
        end
      end
    end
  end
end
