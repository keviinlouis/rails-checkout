require 'rest-client'
require 'checkout/modules/wirecard/webhook'

module Checkout
  module Wirecard
    class Api
      SANDBOX_URL = 'https://sandbox.moip.com.br'
      PRODUCTION_URL = 'https://api.moip.com.br'
      VERSION = 'v2'

      def initialize(auth)
        @auth = auth
        @api = Moip2::Api.new(@auth.get_client)
      end

      # @param [Order] order
      # @param [Payment] payment
      def pay (order, payment)
        wirecard_order = create_order order

        wirecard_payment = create_payment(wirecard_order[:id], payment)

        {
          order: wirecard_order,
          payment: wirecard_payment
        }
      end

      def pay_with_hash(order_hash, payment_hash)
        order = Checkout::Resource::Order.from_hash(order_hash)

        payment = Checkout::Resource::Payment.from_hash(payment_hash)

        pay(order, payment)
      end

      # @param [Order] order
      def create_order(order)
        wirecard_order = @api.order.create order.to_wirecard

        check_errors wirecard_order

        wirecard_order
      end

      # @param [String] order_id
      # @param [Payment] payment
      def create_payment(order_id, payment)
        wirecard_payment = @api.payment.create order_id, payment.to_wirecard

        check_errors wirecard_payment

        wirecard_payment
      end

      def list_orders
        get 'orders'
      end

      def show_order(id)
        get "orders/#{id}"
      end

      def show_payment(id)
        get "payments/#{id}"
      end

      # @param [Webhook] webhook
      def create_webhook(webhook, force = false)
        webhooks = list_webhooks

        has_same_webhook = !webhooks.find { |w| w["target"] == webhook.url && w["events"] == webhook.events }.nil?

        return false if has_same_webhook && !force

        data = {
          events: webhook.events,
          target: webhook.url,
          media: "WEBHOOK"
        }

        post('preferences/notifications', data)
      end

      def list_webhooks
        get 'preferences/notifications'
      end

      def remove_webhook(webhook)
        webhooks = list_webhooks

        wirecard_webhook = webhooks.find { |w| w["target"] == webhook.url && w["events"] == webhook.events }

        return true if wirecard_webhook === false

        delete("preferences/notifications/#{wirecard_webhook["id"]}")
      end

      def setup_webhook_base(events = %w(ORDER.* Payment.*))
        webhook_url = Checkout.configuration.wirecard[:webhook_url]

        webhook = Checkout::Wirecard::Webhook.new(
          webhook_url,
          events
        )

        create_webhook(webhook)
      end

      private

      def base_url
        url = @auth.is_sandbox? ? SANDBOX_URL : PRODUCTION_URL

        "#{url}/#{VERSION}"
      end

      def header
        authorization = @auth.is_oauth? ? "OAuth #{@auth.get_oauth_token}" : "Basic #{@auth.get_basic_token}"

        {
          Authorization: authorization,
          content_type: :json
        }
      end

      def get(url)
        response = RestClient.get("#{base_url}/#{url}", header)

        JSON.parse(response)
      end

      def post(url, body)
        body_json = body.to_json

        response = RestClient.post("#{base_url}/#{url}", body_json, header)

        JSON.parse(response)
      end

      def delete(url)
        RestClient.delete("#{base_url}/#{url}", header)
      end

      def check_errors(response)
        if response.success?
          return
        end
        response_hash = response.to_hash

        raise Checkout::Exception::DataValidationError.new(response_hash[:errors]) unless response_hash[:errors].nil?

        raise Checkout::Exception::AuthNotFounded.new if JSON.parse! response.body
      end
    end
  end
end


