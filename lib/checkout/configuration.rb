module Checkout
  class Configuration
    attr_accessor :wirecard

    def initialize
      @wirecard = nil
    end
  end
end