module Checkout
  module Resource
    class Customer
      attr_accessor :shipping_address, :email, :tax_document, :id, :full_name, :phone

      def initialize(id, full_name, email, tax_document, shipping_address, phone)
        @id = id
        @full_name = full_name
        @email = email
        @tax_document = tax_document
        @shipping_address = shipping_address
        @phone = phone
      end

      def to_wirecard
        {
          own_id: @id,
          fullname: @full_name,
          email: @email,
          taxDocument: @tax_document.to_wirecard,
          shippingAddress: @shipping_address.to_wirecard,
          phone: @phone.to_wirecard,
        }
      end

      def self.from_hash(hash)
        shipping_address = Checkout::Resource::ShippingAddress.from_hash(hash[:shipping_address])
        customer_document = Checkout::Resource::TaxDocument.from_hash(hash[:tax_document])
        customer_phone = Checkout::Resource::Phone.from_hash(hash[:phone])

        return self.new(
          hash[:id],
          hash[:full_name],
          hash[:email],
          customer_document,
          shipping_address,
          customer_phone
        )
      end
    end
  end
end
