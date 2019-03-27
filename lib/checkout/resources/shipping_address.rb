module Checkout
  module Resource
    class ShippingAddress
      def initialize(zip_code, street, street_number, city, district, state, complement = '', country = "BRA")
        @zip_code = zip_code.sub('-', '')
        @street = street
        @street_number = street_number
        @complement = complement
        @city = city
        @district = district
        @state = state
        @country = country
      end

      def to_wirecard
        {
          zipCode: @zip_code,
          street: @street,
          streetNumber: @street_number,
          complement: @complement,
          city: @city,
          district: @district,
          state: @state,
          country: @country,
        }
      end

      def self.from_hash(hash)
        return self.new(
          hash[:zip_code],
          hash[:street],
          hash[:street_number],
          hash[:city],
          hash[:district],
          hash[:state],
          hash[:complement],
          hash[:country] || "BRA",
        )
      end
    end
  end
end