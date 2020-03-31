module Checkout
  module Resource
    class Order
      attr_accessor :gateway_id

      def initialize(id, items, customer, amount = Amount.new, receivers = [], gateway_id = nil)
        @id = id
        @items = items
        @customer = customer
        @receivers = receivers
        @amount = amount
        @gateway_id = gateway_id
      end

      def to_wirecard
        {
          own_id: @id,
          items: @items.map(&:to_wirecard),
          customer: @customer.to_wirecard,
          receivers: @receivers.map(&:to_wirecard),
          amount: @amount.to_wirecard
        }
      end

      def to_getnet
        {
          amount: @amount.to_getnet,
          customer: @customer.to_wirecard,
        }
      end

      def self.from_hash(hash)
        customer_hash = hash[:customer]

        items = hash[:items].map do |item|
          Checkout::Resource::Product.from_hash item
        end

        customer = Checkout::Resource::Customer.from_hash(customer_hash)

        return new(
          hash[:id],
          items,
          customer
        )
      end

      def add_gateway_id(id)
        @gateway_id = id
      end
    end
  end
end