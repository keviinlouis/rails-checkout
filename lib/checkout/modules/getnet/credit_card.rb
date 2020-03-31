module Checkout
  module Getnet
    module CreditCard
      def credit_card_token(credit_card_number, customer_id = nil)
        payload = {
          card_number: credit_card_number.gsub(/[^\d]/, '')
        }

        payload[:customer_id] = customer_id unless customer_id.nil?

        post('/v1/tokens/card', payload)
      end
    end
  end
end