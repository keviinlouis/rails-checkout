module Checkout
  class Configuration
    attr_accessor :wirecard, :getnet

    def initialize
      @wirecard = nil
      @getnet = nil
    end
  end
end