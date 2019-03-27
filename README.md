# Checkout

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/checkout`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

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

### Wirecard

Create a initializer in config/initializers, (e.g. checkout.rb)

```ruby
require "checkout"

Checkout.configure do |c|
    c.wirecard = {
      key: 'WIRECARD_KEY',
      token: 'WIRECARD_TOKEN',
      webhook_url: 'WEBHOOK_URL'
    }
end
```

After, in your controller, you need to initialize a Wirecard Api
```ruby
auth = Checkout::Wirecard::Auth.new :development
gateway = Checkout::Wirecard::Api.new(auth)
```

You can also pass a oauth token like: 
```ruby
oauth_token = "some_oauth_token"
auth = Checkout::Wirecard::Auth.new(:development, oauth_token)
gateway = Checkout::Wirecard::Api.new(auth)

```
#### Environment
Wirecard has two environments: 
- Sandbox (development)
```ruby
Checkout::Wirecard::Auth.new(:development)
```
- Production (production)
```ruby
Checkout::Wirecard::Auth.new(:production)
```

#### Webhook
Wirecard return the update events by sending a post request for a url you can set
After configuring the keys and webhook url, you can easily setup the webhook with the default events (ORDER.* and Payment.*)
```ruby
auth = Checkout::Wirecard::Auth.new(:production)
gateway = Checkout::Wirecard::Api.new(auth)
gateway.setup_webhook_base
```
Or you can pass another events as you wish
```ruby
auth = Checkout::Wirecard::Auth.new(:production)
gateway = Checkout::Wirecard::Api.new(auth)
gateway.setup_webhook_base(["ORDER.CREATED"])
```

For a list of all events, you can access https://dev.wirecard.com.br/reference#eventos

You also can create a webhook with another url
```ruby
webhook = Checkout::Wirecard::Webhook.new(
    'some_url', #url
    ['ORDER.WAITING'] #events
)

auth = Checkout::Wirecard::Auth.new(:production)
gateway = Checkout::Wirecard::Api.new(auth)
gateway.create_webhook(webhook)
```

### Creating order and payment with hash 
One wat to create a order and payment is by passing two hashes to the method pay_with_hash<br>
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
 gateway.pay_with_hash order_hash, payment_hash
```

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
auth = Checkout::Wirecard::Auth.new(:production)
gateway = Checkout::Wirecard::Api.new(auth)
wirecard_order = gateway.create_order order
```

If some data is not valid, the exception ```Checkout::Exceptions::DataValidationError ``` will raise <br>
If some auth is not valid, the exception ```Checkout::Exceptions::AuthNotFounded ``` will raise

After you need to save the id of wirecard in order object
```ruby
order.add_gateway_id wirecard_order[:id]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/rails-checkout. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.