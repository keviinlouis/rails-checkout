module Checkout
  module Resource
    class Holder
      def initialize(full_name, birth_date, tax_document)
        @full_name = full_name
        @birth_date = birth_date
        @tax_document = tax_document
      end

      def to_wirecard
        {
          fullname: @full_name,
          birthdate: @birth_date,
          taxDocument: @tax_document.to_wirecard
        }
      end

      def self.from_hash(hash)
        holder_tax_document = Checkout::Resource::TaxDocument.from_hash(hash[:tax_document])

        return self.new(
          hash[:fullname],
          hash[:birthdate],
          holder_tax_document
        )
      end
    end
  end
end