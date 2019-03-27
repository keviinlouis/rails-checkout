module Checkout
  module Resource
    class Product
      def initialize(description, quantity, price)
        @description = description
        @quantity = quantity
        @price = price
      end

      def to_wirecard
        {
          product: @description,
          quantity: @quantity,
          price: @price * 100
        }
      end

      def self.from_hash(hash)
        return self.new(
          hash[:product],
          hash[:quantity],
          hash[:price]
        )
      end
    end
  end
end