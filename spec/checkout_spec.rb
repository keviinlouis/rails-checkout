require 'pry'
require 'checkout'

RSpec.describe Checkout do
  before(:each) do
    @gateway = Checkout::Wirecard::Api.new(Checkout::Wirecard::Auth.new :development)
  end

  it "has a version number" do
    expect(Checkout::VERSION).not_to be nil
  end

  describe "create_order" do
    it 'should create a order' do
      items = (1..2).map do |i|
        Checkout::Resource::Product.new("Product #{i}", 1 + rand(3), 1 + rand(100))
      end

      shipping_address = Checkout::Resource::ShippingAddress.new(
        '81750-410',
        'Some Street',
        123,
        'Some City',
        'Some District',
        'Some State'
      )

      customer_document = Checkout::Resource::TaxDocument.new(:CPF, '123.456.789.09')

      customer_phone = Checkout::Resource::Phone.new('41', '99999999')

      customer = Checkout::Resource::Customer.new(
        1,
        'Test Name',
        'test_email@mail.com',
        customer_document,
        shipping_address,
        customer_phone
      )

      order = Checkout::Resource::Order.new(
        1,
        items,
        customer
      )
      wirecard_order = @gateway.create_order order

      expect(wirecard_order.own_id.to_i).to eq 1
      expect(wirecard_order.items.size).to eq 2
    end

    it 'should return errors' do
      items = (1..2).map do |i|
        Checkout::Resource::Product.new("Product #{i}", 0, 0)
      end

      shipping_address = Checkout::Resource::ShippingAddress.new(
        '81750-410',
        'Rua Pedro Ramos de Oliverira',
        354,
        '',
        'Curitiba',
        'Alto Boqueirao',
        'Paraná'
      )

      customer_document = Checkout::Resource::TaxDocument.new(:CPF, '123.456.789.09')

      customer_phone = Checkout::Resource::Phone.new('41', '99999999')

      customer = Checkout::Resource::Customer.new(
        1,
        'Test Name',
        'test_email@mail.com',
        customer_document,
        shipping_address,
        customer_phone
      )

      order = Checkout::Resource::Order.new(
        1,
        items,
        customer
      )
      begin
        @gateway.create_order order
      rescue => e
        expect(e.class).to eq Checkout::Exception::DataValidationError
        expect(e.errors.size).not_to eq 0
      end
    end
  end

  describe "create_payment" do
    before(:each) do
      @items = (1..2).map do |i|
        Checkout::Resource::Product.new("Product #{i}", 1, 100)
      end

      @shipping_address = Checkout::Resource::ShippingAddress.new(
        '81750-410',
        'Rua Pedro Ramos de Oliverira',
        354,
        'Curitiba',
        'Alto Boqueirao',
        'Paraná',
        ''
      )

      @customer_document = Checkout::Resource::TaxDocument.new(:CPF, '123.456.789.09')

      @customer_phone = Checkout::Resource::Phone.new('41', '99999999')

      @customer = Checkout::Resource::Customer.new(
        1,
        'Test Name',
        'test_email@mail.com',
        @customer_document,
        @shipping_address,
        @customer_phone
      )

      @order = Checkout::Resource::Order.new(
        1,
        @items,
        @customer
      )

      @wirecard_order = @gateway.create_order @order

      @order.add_gateway_id @wirecard_order[:id]
    end
    it 'should create a payment with credit card' do
      holder_document = Checkout::Resource::TaxDocument.new(:CPF, '123.456.789.09')

      holder = Checkout::Resource::Holder.new(
        'Some Full Name',
        '1988-12-30',
        holder_document
      )

      funding_instrument = Checkout::Resource::CreditCard.new(
        'XhYrQBfMz+5T3KPqZ2kgitX9BtSJErYYzw0lUqkHig8+0gTDfJV+rYng0Sg1xK03UU1kHijHmK27QQ7SDKnx/R1xPF/Ph3k+c17FM+ybK/KdyDM5uQPivM7h0CFp/Gc/6RMiiIRRFS1GGZxynaJtZIUa4dhhrniMXMQKCJre78Xxq2Fiy/K1UvVTnxEpgh4TWnZgXy82tPyGm1qpQt99/6WFIHivWD1epdaINur4KAM3z64CIvoKVZ0kqHit9EZaXYuAfeLbrdL/Hke2Jdolh1+dubk0BbjfV8bQtI6GuUebsugnicenqxQO5IifNwXOBz9Hi9KFuiQYf0XlMBeX3g==',
        holder
      )

      payment = Checkout::Resource::Payment.new(
        'Some Store',
        3,
        funding_instrument
      )
      wirecard_payment = @gateway.create_payment @order.gateway_id, payment
      expect(wirecard_payment[:id]).not_to be_nil
      expect(wirecard_payment[:status]).to eq 'IN_ANALYSIS'
      expect(wirecard_payment[:amount][:total]).to eq 20000
      expect(wirecard_payment[:funding_instrument][:method]).to eq "CREDIT_CARD"
      expect(wirecard_payment[:funding_instrument][:credit_card]).not_to be_nil
    end

    it 'should return errors when credit card hash is invalid' do
      holder_document = Checkout::Resource::TaxDocument.new(:CPF, '123.456.789.09')

      holder = Checkout::Resource::Holder.new(
        'Some Full Name',
        '1988-12-30',
        holder_document
      )

      funding_instrument = Checkout::Resource::CreditCard.new(
        'some_invalid_credit_card_hash',
        holder
      )

      payment = Checkout::Resource::Payment.new(
        'Some Store',
        3,
        funding_instrument
      )

      begin
        @gateway.create_payment @order.gateway_id, payment
      rescue => e
        expect(e.class).to eq Checkout::Exception::DataValidationError
        expect(e.errors.size).to eq 1
        error = e.errors.first
        expect(error[:code]).to eq "PAY-014"
      end
    end

    it 'should create a payment with boleto' do
      funding_instrument = Checkout::Resource::Ticket.new(
        'https://some.logo.com/some_image.jpg',
        (Date.today + 5),
        [
          'Some instruction 1',
          'Some instruction 2',
          'Some instruction 3'
        ]
      )

      payment = Checkout::Resource::Payment.new(
        'Some Store',
        1,
        funding_instrument
      )


      wirecard_payment = @gateway.create_payment @order.gateway_id, payment

      expect(wirecard_payment[:id]).not_to be_nil
      expect(wirecard_payment[:status]).to eq 'WAITING'
      expect(wirecard_payment[:amount][:total]).to eq 20000
      expect(wirecard_payment[:funding_instrument][:method]).to eq "BOLETO"
      expect(wirecard_payment[:funding_instrument][:boleto]).not_to be_nil
      expect(wirecard_payment[:funding_instrument][:boleto][:expiration_date]).to eq (Date.today + 5).strftime("%Y-%m-%d")
      expect(wirecard_payment[:funding_instrument][:boleto][:line_code]).not_to be_nil
      expect(wirecard_payment[:_links][:pay_boleto][:print_href]).not_to be_nil
    end

    it 'should return error when expiration date is invalid' do
      funding_instrument = Checkout::Resource::Ticket.new(
        'https://some.logo.com/some_image.jpg',
        (Date.today - 4),
        [
          'Some instruction 1',
          'Some instruction 2',
          'Some instruction 3'
        ]
      )

      payment = Checkout::Resource::Payment.new(
        'Some Store',
        1,
        funding_instrument
      )

      begin
        @gateway.create_payment @order.gateway_id, payment
      rescue => e
        expect(e.class).to eq Checkout::Exception::DataValidationError
        expect(e.errors.size).to eq 1
        error = e.errors.first
        expect(error[:code]).to eq "PAY-644"
      end
    end
  end

  describe "create_order_with_payment" do
    it 'should create order and payment and return both' do
      items = (1..2).map do |i|
        Checkout::Resource::Product.new("Product #{i}", 1, 100)
      end

      shipping_address = Checkout::Resource::ShippingAddress.new(
        '81750-410',
        'Some Street',
        123,
        'Some City',
        'Some District',
        'Some State'
      )

      customer_document = Checkout::Resource::TaxDocument.new(:CPF, '123.456.789.09')

      customer_phone = Checkout::Resource::Phone.new('41', '99999999')

      customer = Checkout::Resource::Customer.new(
        1,
        'Test Name',
        'test_email@mail.com',
        customer_document,
        shipping_address,
        customer_phone
      )

      order = Checkout::Resource::Order.new(
        1,
        items,
        customer
      )

      holder_document = Checkout::Resource::TaxDocument.new(:CPF, '123.456.789.09')

      holder = Checkout::Resource::Holder.new(
        'Some Full Name',
        '1988-12-30',
        holder_document
      )

      funding_instrument = Checkout::Resource::CreditCard.new(
        'XhYrQBfMz+5T3KPqZ2kgitX9BtSJErYYzw0lUqkHig8+0gTDfJV+rYng0Sg1xK03UU1kHijHmK27QQ7SDKnx/R1xPF/Ph3k+c17FM+ybK/KdyDM5uQPivM7h0CFp/Gc/6RMiiIRRFS1GGZxynaJtZIUa4dhhrniMXMQKCJre78Xxq2Fiy/K1UvVTnxEpgh4TWnZgXy82tPyGm1qpQt99/6WFIHivWD1epdaINur4KAM3z64CIvoKVZ0kqHit9EZaXYuAfeLbrdL/Hke2Jdolh1+dubk0BbjfV8bQtI6GuUebsugnicenqxQO5IifNwXOBz9Hi9KFuiQYf0XlMBeX3g==',
        holder
      )

      payment = Checkout::Resource::Payment.new(
        'Some Store',
        3,
        funding_instrument
      )

      wirecard_response = @gateway.pay order, payment

      wirecard_order = wirecard_response[:order]
      wirecard_payment = wirecard_response[:payment]

      expect(wirecard_payment[:id]).not_to be_nil
      expect(wirecard_payment[:status]).to eq 'IN_ANALYSIS'
      expect(wirecard_payment[:amount][:total]).to eq 20000
      expect(wirecard_payment[:funding_instrument][:method]).to eq "CREDIT_CARD"
      expect(wirecard_payment[:funding_instrument][:credit_card]).not_to be_nil

      expect(wirecard_order.own_id.to_i).to eq 1
      expect(wirecard_order.items.size).to eq 2
    end
  end

  context "should create order and payment by hash" do
    before(:each) do
      @order_hash = {
        id: 1,
        items: [
          { product: 'Product 1', quantity: 1, price: 100 },
          { product: 'Product 2', quantity: 1, price: 100 },
          { product: 'Product 3', quantity: 1, price: 100 },
        ],
        customer: {
          id: 1,
          full_name: 'Full Name',
          email: 'some@email.com',
          tax_document: {
            type: "CPF",
            number: "12345678909",
          },
          shipping_address: {
            zip_code: "81750-410",
            street: "Some street",
            street_number: 123,
            city: "Some City",
            district: "Some District",
            state: "Some State",
            complement: "Some Complement",
            country: "BR",
          },
          phone: {
            area_code: "41",
            number: "999999999"
          }
        }
      }
    end

    it 'with credit card' do
      payment_hash = {
        statement_descriptor: "Description",
        installment_count: 1,
        funding_instrument: {
          credit_card: {
            hash: "XhYrQBfMz+5T3KPqZ2kgitX9BtSJErYYzw0lUqkHig8+0gTDfJV+rYng0Sg1xK03UU1kHijHmK27QQ7SDKnx/R1xPF/Ph3k+c17FM+ybK/KdyDM5uQPivM7h0CFp/Gc/6RMiiIRRFS1GGZxynaJtZIUa4dhhrniMXMQKCJre78Xxq2Fiy/K1UvVTnxEpgh4TWnZgXy82tPyGm1qpQt99/6WFIHivWD1epdaINur4KAM3z64CIvoKVZ0kqHit9EZaXYuAfeLbrdL/Hke2Jdolh1+dubk0BbjfV8bQtI6GuUebsugnicenqxQO5IifNwXOBz9Hi9KFuiQYf0XlMBeX3g==",
            holder: {
              fullname: "Some Full Name",
              birthdate: "1995-12-30",
              tax_document: {
                type: "CPF",
                number: "12345678909"
              }
            }
          }
        }
      }
      @gateway.pay_with_hash @order_hash, payment_hash
    end

    it 'with boleto' do
      payment_hash = {
        statement_descriptor: "Description",
        installment_count: 1,
        funding_instrument: {
          boleto: {
            logo: 'https://some.logo.com/some_image.jpg',
            expiration_date: (Date.today + 4),
            instruction_lines: [
              'Some instruction 1',
              'Some instruction 2',
              'Some instruction 3'
            ],
          }
        }
      }
      @gateway.pay_with_hash @order_hash, payment_hash
    end

  end
end
