module Checkout
  module Resource
    class TaxDocument
      TYPES = %w(CPF CNPJ)

      def initialize(type, number)
        @type = type.to_s
        @number = number
        validate
      end

      def to_wirecard
        {
          type: @type,
          number: @number
        }
      end

      def validate
        throw Checkout::Exception::DataValidationError unless TYPES.include? @type
        throw Checkout::Exception::DataValidationError if @number.empty?
      end

      def self.from_hash(hash)
        return self.new(
          hash[:type],
          hash[:number]
        )
      end
    end
  end
end