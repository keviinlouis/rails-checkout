module Checkout
  module Exception
    class DataValidationError < StandardError
      attr_accessor :errors

      def initialize(errors = [])
        @errors = errors

        super
      end
    end
  end
end
