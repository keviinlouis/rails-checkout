module Checkout
  module Resource
    class Amount
      def initialize(currency = "BRL", shipping = 0, addition = 0, discount = 0)
        @currency = currency
        @shipping = shipping
        @addition = addition
        @discount = discount
      end

      def to_wirecard
        {
          currency: @currency,
          subtotals: {
            shipping: @shipping * 100,
            addition: @addition * 100,
            discount: @discount * 100
          }
        }
      end
    end
  end
end