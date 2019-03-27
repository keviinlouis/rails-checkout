module Checkout
  module Resource
    class CreditCard
      def initialize(hash, holder)
        @hash = hash
        @holder = holder
      end

      def to_wirecard
        {
          method: "CREDIT_CARD",
          creditCard: {
            hash: @hash,
            holder: @holder.to_wirecard
          }
        }
      end

      def self.from_hash(hash)
        holder = Checkout::Resource::Holder.from_hash(
          hash[:holder]
        )
        return self.new(
          hash[:hash],
          holder
        )
      end
    end
  end
end