module Checkout
  module Wirecard
    class Webhook
      attr_accessor :url, :events
      EVENTS = %w(ORDER.* ORDER.CREATED ORDER.WAITING ORDER.PAID ORDER.NOT_PAID ORDER.REVERTED PAYMENT.* PAYMENT.CREATED PAYMENT.WAITING PAYMENT.IN_ANALYSIS PAYMENT.PRE_AUTHORIZED PAYMENT.AUTHORIZED PAYMENT.CANCELLED PAYMENT.REFUNDED PAYMENT.REVERSED PAYMENT.SETTLED REFUND.* REFUND.REQUESTED REFUND.COMPLETED REFUND.FAILED TRANSFER.* TRANSFER.REQUESTED TRANSFER.COMPLETED TRANSFER.FAILED ESCROW.* ESCROW.HOLD_PENDING ESCROW.HELD ESCROW.RELEASED)

      def initialize(url, events)
        @url = url
        @events = events.map(&:upcase)

        validate
      end

      def validate
        throw Checkout::Exception::DataValidationError(['Wirecard Webhook Event not founded']) if (EVENTS - @events).size == EVENTS.size
        throw Checkout::Exception::DataValidationError(['Wirecard Webhook Url is required']) if @url.blank?
      end
    end
  end
end


