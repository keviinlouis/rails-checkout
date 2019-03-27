module Checkout
  module Exception
    class OrderCreateError < StandardError
      attr_accessor :error

      def initialize(error)
        @error = error
      end
    end
  end
end