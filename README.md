# Checkout

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails-checkout'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rails-checkout

## Usage

You need to set the access keys for the payment gateway

The methods we support today are:
- [x] Wirecard
- [ ] Paypal
- [ ] PagSeguro
- [ ] MercadoPago

To plug and play the gem, follow the steps:

1 - Install the gem <br>
2 - Create checkout.rb in initializers<br>
3 - Configure the keys of your gateway<br>
4 - Check if your gateway have some additional configuration (e.g. Wirecard Webhook)<br>
5 - Create the hash or resources objects<br>
6 - Create your order and payment <br>

### Documentation for gateways
[Wirecard](https://github.com/ateliware/rails-checkout/docs/wirecard.md)

### Creating order and payment with hash 
One wat to create a order and payment is by passing two hashes to the method pay_with_hash<br>
`For description field by field, check creating order and payment with resource`
For the order hash you can set like this:
```ruby
order_hash = {
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
```
##### Credit Card Payment
For the payment with credit card hash you can set like this:
```ruby
payment_hash = {
 statement_descriptor: "Description",
 installment_count: 1,
 funding_instrument: {
   credit_card: {
     hash: "credit card hash",
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
```
##### Ticket (Boleto) Payment
For the payment with ticket (boleto) hash you can set like this:
```ruby
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
```

This method will create the object for each level in the hash and validate the data<br>
After you can call the method
```ruby
gateway = Checkout::Wirecard::Api.new
response = gateway.pay_with_hash order_hash, payment_hash
```
After creation, the following response will return, in case of success
```ruby
{
  order: object_gateway_order_response,
  payment: object_gateway_order_response
}
```

To check how the response its come, check documentation of each gateway
You can get the data of wirecard with this response

### Creating order and payment with resources objects
One way to create a order and payment is by instance of objects called Resources

##### Products
You need 3 params for creating a product:
- Description (String)
- Quantity (Integer)
- Value (Float)

The product resource automatically transform the value for cents 
https://dev.wirecard.com.br/reference#criar-pedido-2

```ruby
items = [
    Checkout::Resource::Product.new(
        "Some product", #description
        1, #quantity
        12.54 #value
    )
]
```

##### Shipping Address
You need 7 params for creating a product:
- Zip Code (String)
- Street (String)
- Street number (Integer)
- City (String)
- District (String)
- State (String)
- Complement (String) *optional* 
- Country (String) *optional* 

```ruby
shipping_address = Checkout::Resource::ShippingAddress.new(
    '00000-000', #Zip Code eg 9999999 or 99999-999
    'Street', #Street eg Rua Almeida de campos
    123, #Street number 
    'City', #City
    'District', #District
    'State', #State
    'Complement' #Complement
)
```
##### Tax Document
You need just 2 params for creating TaxDocument Resource:
- Type (String) [Values: CPF or CNPJ]
- Number (String) [You can pass with or without special character]

```ruby
customer_document = Checkout::Resource::TaxDocument.new("CPF", '123.456.789.09')
```

##### Phone
You need 3 params for creating Phone Resource
- Area Code (String)
- Phone number (String)
- Country Code (String) *optional*
```ruby
customer_phone = Checkout::Resource::Phone.new('00', '99999999')
```

##### Customer
You need 6 params for creating a Customer Resource:
- ID (Integer or String)
- Full name (String)
- Email (String)
- Tax Document (Checkout::Resource::TaxDocument)
- Shipping Address (Checkout::Resource::ShippingAddress)
- Phone (Checkout::Resource::Phone)

```ruby
customer = Checkout::Resource::Customer.new(
    1,
    'Test Name',
    'test_email@mail.com',
    customer_document,
    shipping_address,
    customer_phone
)
```

##### Order
You need 3 params for creating a Order Resource:
- ID (Integer or String)
- Items (Array of Checkout::Resource::Products)
- Customer (Checkout::Resource::Customer)

```ruby
order = Checkout::Resource::Order.new(
    1,
    items,
    customer
)
```

#### Sending Order
Create the gateway api and call create order
```ruby
gateway = Checkout::Wirecard::Api.new
geteway_order_object = gateway.create_order order
```
If some data is not valid, the exception ```Checkout::Exceptions::DataValidationError ``` will raise <br>
If some auth is not valid, the exception ```Checkout::Exceptions::AuthNotFounded ``` will raise

After you need to save the id of wirecard in order object
```ruby
order.add_gateway_id wirecard_order[:id]
```

#### Sending Payment
After getting gateway id, you now can create a payment calling create_payment method
```ruby
geteway_payment_object = gateway.create_payment order.gateway_id, payment
```

#### Sending order and payment
You also can send both at once, calling pay method
 ```ruby
gateway_response = gateway.pay(order, payment)
```
After creation, the following response will return, in case of success
```ruby
{
  order: object_gateway_order_response,
  payment: object_gateway_order_response
}
```

To check how the response its come, check documentation of each gateway

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ateliware/rails-checkout. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.
