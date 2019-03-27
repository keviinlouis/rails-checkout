module Checkout
  module Resource
    class Ticket
      # @param [String] logo
      # @param [Date] expiration_date
      # @param [Array[String]] instruction_lines
      def initialize(logo, expiration_date, instruction_lines = [])
        @logo = logo
        @expiration_date = expiration_date.class == String ? expiration_date : expiration_date.strftime("%Y-%m-%d")
        @instruction_lines = instruction_lines
      end

      def to_wirecard
        {
          method: "BOLETO",
          boleto: {
            expiration_date: @expiration_date,
            instruction_lines: {
              first: @instruction_lines[0],
              second: @instruction_lines[1],
              third: @instruction_lines[2]
            },
            logo_uri: @logo
          }
        }
      end

      def self.from_hash(hash)
        return self.new(
          hash[:logo],
          hash[:expiration_date],
          hash[:instruction_lines]
        )
      end
    end
  end
end

