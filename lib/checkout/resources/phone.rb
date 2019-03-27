module Checkout
  module Resource
    class Phone
      def initialize(area_code, number, country_code = "55")
        @area_code = area_code
        @number = number
        @country_code = country_code
      end

      def to_wirecard
        {
          countryCode: @country_code,
          areaCode: @area_code,
          number: @number
        }
      end

      def self.from_hash(hash)
        return self.new(
          hash[:area_code],
          hash[:number]
        )
      end
    end
  end
end