require 'checkout/version'
require 'checkout/configuration'

require 'checkout/modules/wirecard/api'
require 'checkout/modules/wirecard/auth'

require 'checkout/modules/getnet/auth'
require 'checkout/modules/getnet/credit_card'
require 'checkout/modules/getnet/api'

require 'checkout/resources/product'
require 'checkout/resources/shipping_address'
require 'checkout/resources/customer'
require 'checkout/resources/order'
require 'checkout/resources/tax_document'
require 'checkout/resources/amount'
require 'checkout/resources/phone'
require 'checkout/resources/credit_card'
require 'checkout/resources/holder'
require 'checkout/resources/payment'
require 'checkout/resources/ticket'

require 'checkout/exceptions/data_validation_error'
require 'checkout/exceptions/auth_not_founded'
require 'checkout/exceptions/environment_not_founded'
require 'checkout/exceptions/payment_create_error'

require 'checkout/model'

module Checkout
  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= Checkout::Configuration.new
  end

  def self.reset
    @configuration = Checkout::Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end