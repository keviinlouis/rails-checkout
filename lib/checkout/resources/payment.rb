module Checkout
  module Resource
    class Payment
      def initialize(statement_descriptor, installment_count, funding_instrument)
        @statement_descriptor = statement_descriptor
        @installment_count = installment_count
        @funding_instrument = funding_instrument
      end

      def to_wirecard
        validate_wirecard
        {
          statementDescriptor: @statement_descriptor,
          installmentCount: @installment_count,
          funding_instrument: @funding_instrument.to_wirecard
        }
      end

      def self.from_hash(hash)
        funding_instrument_hash = hash[:funding_instrument]
        credit_card_hash = funding_instrument_hash[:credit_card]
        boleto_hash = funding_instrument_hash[:boleto]

        if !credit_card_hash.nil?
          funding_instrument = Checkout::Resource::CreditCard.from_hash(credit_card_hash)
        elsif !boleto_hash.nil?
          funding_instrument = Checkout::Resource::Ticket.from_hash(boleto_hash)
        else
          raise Checkout::Exception::DataValidationError.new(['Payment method is missing'])
        end

        return self.new(
          hash[:statement_descriptor],
          hash[:installment_count],
          funding_instrument
        )
      end

      def validate_wirecard
        if @statement_descriptor.length > 13
          raise Checkout::Exception::DataValidationError.new(['Statement Descriptor mus be less or equal to 13 characters'])
        end
      end
    end
  end
end