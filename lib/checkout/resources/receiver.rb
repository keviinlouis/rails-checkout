module Checkout
  module Resource
    class Receiver
      AMOUNT_TYPES = [:fixed, :percentual]
      TYPES = [:primary, :secondary]

      # @param [String] type
      # @param [Boolean] fee_payor
      # @param [String] moip_account
      # @param [Float] amount
      # @param [String] amount_type
      def initialize(type = :primary, fee_payor, moip_account, amount, amount_type, value)
        @type = type
        @fee_payor = fee_payor
        @moip_account = moip_account
        @amount = amount
        @amount_type = amount_type
      end

      def to_wirecard
        amount = if is_percentual?
                   { percentual: @amount }
                 else
                   { fixed: @amount * 100 }
                 end
        {
          type: @type,
          feePayor: @fee_payor,
          moipAccount: @moip_account,
          amount: amount
        }
      end

      def is_percentual?
        @amount_type == :percentual
      end

      def is_fixed?
        @amount_type == :fixed
      end
    end
  end
end