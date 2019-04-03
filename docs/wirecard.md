## Wirecard

### Wirecard resources supported 
The methods we support today are:
- [x] Order
- [x] Payment Credit Card
- [x] Payment Ticket (Boleto)
- [x] Receivers (Split Payment)
- [x] Webhook Config
- [ ] Create wirecard account
- [ ] Signature

### Configuration
Create a initializer in config/initializers, (e.g. checkout.rb)

```ruby
require "checkout"

Checkout.configure do |c|
    c.wirecard = {
      key: 'WIRECARD_KEY',
      token: 'WIRECARD_TOKEN',
      webhook_url: 'WEBHOOK_URL',
      env: :development
    }
end
```

#### Environment
Wirecard has two environments: 
- Sandbox (development)
```ruby
c.wirecard = {
  key: 'WIRECARD_KEY',
  token: 'WIRECARD_TOKEN',
  webhook_url: 'WEBHOOK_URL',
  env: :development
}
```
- Production (production)
```ruby
c.wirecard = {
  key: 'WIRECARD_KEY',
  token: 'WIRECARD_TOKEN',
  webhook_url: 'WEBHOOK_URL',
  env: :production
}
```

After, in your controller, you need to initialize a Wirecard Api
```ruby
gateway = Checkout::Wirecard::Api.new
```

You can also pass a oauth token like: 
```ruby
oauth_token = "some_oauth_token"
gateway = Checkout::Wirecard::Api.new(oauth_token)

```

#### Webhook
Wirecard return the update events by sending a post request for a url you can set<br>
After configuring the keys and webhook url, you can easily setup the webhook with the default events (ORDER.* and Payment.*)
```ruby
gateway = Checkout::Wirecard::Api.new
gateway.setup_webhook_base
```
Or you can pass another events as you wish
```ruby
gateway = Checkout::Wirecard::Api.new
gateway.setup_webhook_base(["ORDER.CREATED"])
```

For a list of all events, you can access https://dev.wirecard.com.br/reference#eventos

You also can create a webhook with another url
```ruby
webhook = Checkout::Wirecard::Webhook.new(
    'some_url', #url
    ['ORDER.WAITING'] #events
)

gateway = Checkout::Wirecard::Api.new
gateway.create_webhook(webhook)
```

#### Response data from wirecard

##### Order
In Order the response will come in this structure
```ruby

RecursiveOpenStruct 
    id="ORD-00000000", 
    own_id="3", 
    status="CREATED", 
    platform="V2", 
    created_at="2019-04-03T14:02:08.975-03", 
    updated_at="2019-04-03T14:02:08.975-03", 
    amount={
        :paid=>0, 
        :total=>9900, 
        :fees=>0, 
        :refunds=>0, 
        :liquid=>0, 
        :other_receivers=>0, 
        :currency=>"BRL", 
        :subtotals=>{
            :shipping=>0, 
            :addition=>0, 
            :discount=>0, 
            :items=>9900
        }
    }, 
    items=[
        {
            :quantity=>1, 
            :price=>9900, 
            :product=>"Product "
        }
    ], 
    customer={
        :id=>"CUS-00000000", 
        :own_id=>"3", 
        :fullname=>"Name", 
        :created_at=>"2019-04-03T14:02:08.979-03", 
        :updated_at=>"2019-04-03T14:02:08.982-03", 
        :email=>"email@email.com", 
        :phone=>{
            :country_code=>"55", 
            :area_code=>"41", 
            :number=>"12341234"
        }, 
        :tax_document=>{
            :type=>"CPF", 
            :number=>"00000000000"
        }, 
        :shipping_address=>{
            :zip_code=>"00000000", 
            :street=>"Street", 
            :street_number=>"number", 
            :complement=>"", 
            :city=>"city", 
            :district=>"destrict", 
            :state=>"ST", 
            :country=>"BRA"
        }, 
        :moip_account=>{
            :id=>"MPA-00000000"
        }, 
        :_links=>{
            :self=>{
                :href=>"https://sandbox.moip.com.br/v2/customers/CUS-000000000"
            }, 
            :hosted_account=>{
                :redirect_href=>"https://hostedaccount-sandbox.moip.com.br?token=000000000&id=CUS-000000000&mpa=MPA-000000000"
            }
        }
    }, 
    payments=[], 
    escrows=[], 
    refunds=[], 
    entries=[], 
    events=[
        {
            :type=>"ORDER.CREATED", 
            :created_at=>"2019-04-03T14:02:08.975-03", 
            :description=>""
        }
    ], 
    receivers=[
        {
            :moip_account=>{
                :id=>"MPA-000000000", 
                :login=>"email@email.com", 
                :fullname=>"full name"
            }, 
            :type=>"PRIMARY", 
            :amount=>{
                :total=>9900, 
                :currency=>"BRL", 
                :fees=>0, 
                :refunds=>0}, 
                :fee_payor=>true
            }
        ], 
    shipping_address={
        :zip_code=>"00000000", 
        :street=>"Street", 
        :street_number=>"number", 
        :complement=>"", 
        :city=>"city", 
        :district=>"destrict", 
        :state=>"ST", 
        :country=>"BRA"
    }, 
    _links={
        :self=>{
            :href=>"https://sandbox.moip.com.br/v2/orders/ORD-00000000"
        }, 
        :checkout=>{
            :pay_checkout=>{
                :redirect_href=>"https://checkout-new-sandbox.moip.com.br?token=c8c396f3-55d6-4264-9e7e-9e1009e5dd21&id=ORD-00000000"
            }, 
            :pay_credit_card=>{
                :redirect_href=>"https://checkout-new-sandbox.moip.com.br?token=c8c396f3-55d6-4264-9e7e-9e1009e5dd21&id=ORD-00000000&payment-method=credit-card"
            }, 
            :pay_boleto=>{
                :redirect_href=>"https://checkout-new-sandbox.moip.com.br?token=c8c396f3-55d6-4264-9e7e-9e1009e5dd21&id=ORD-00000000&payment-method=boleto"
            }, 
            :pay_online_bank_debit_itau=>{
                :redirect_href=>"https://checkout-sandbox.moip.com.br/debit/itau/ORD-00000000"
            }
        }
    }
```
##### Payment
###### Response with credit card
In Payment with credit card the response will come in this structure
```ruby
RecursiveOpenStruct 
    id="PAY-000000", 
    status="IN_ANALYSIS", 
    delay_capture=false, 
    amount={
        :total=>9900, 
        :gross=>9900, 
        :fees=>0, 
        :refunds=>0, 
        :liquid=>9900, 
        :currency=>"BRL"
    }, 
    installment_count=1, 
    statement_descriptor="FAEL", 
    funding_instrument={
        :credit_card=>{
            :id=>"CRC-000000", 
            :brand=>"VISA", 
            :first6=>"411111", 
            :last4=>"1111", 
            :store=>true, 
            :holder=>{
                :birthdate=>"1995-06-04", 
                :birth_date=>"1995-06-04", 
                :tax_document=>{
                    :type=>"CPF", 
                    :number=>"00000000000"
                }, 
                :fullname=>"full name example"
            }
        }, 
        :method=>"CREDIT_CARD"
    }, 
    acquirer_details={
        :authorization_number=>"T00000", 
        :tax_document=>{
            :type=>"CNPJ", 
            :number=>"00000000000000"
        }
    }, 
    fees=[
        {
            :type=>"TRANSACTION", 
            :amount=>0
        }
    ], 
    events=[
        {
            :type=>"PAYMENT.IN_ANALYSIS", 
            :created_at=>"2019-04-03T14:02:10.181-03"
        }, 
        {
            :type=>"PAYMENT.CREATED", 
            :created_at=>"2019-04-03T14:02:09.835-03"
        }
    ], 
    receivers=[
        {
            :moip_account=>{
                :id=>"MPA-000000", 
                :login=>"login@email.com", 
                :fullname=>"example full name"
            }, 
            :type=>"PRIMARY", 
            :amount=>{
                :total=>9900, 
                :currency=>"BRL", 
                :fees=>0, 
                :refunds=>0
            }, 
            :fee_payor=>true
        }
    ], 
    _links={
        :self=>{
            :href=>"https://sandbox.moip.com.br/v2/payments/PAY-0000000"
        }, 
        :order=>{
            :href=>"https://sandbox.moip.com.br/v2/orders/ORD-000000", 
            :title=>"ORD-000000"
        }
    }, 
    created_at="2019-04-03T14:02:09.833-03", 
    updated_at="2019-04-03T14:02:10.181-03"
```

###### Response With Ticket
In Payment with ticket (boleto) the response will come in this structure
```ruby
RecursiveOpenStruct 
    id="PAY-000000", 
    status="WAITING", 
    delay_capture=false, 
    amount={
        :total=>20000, 
        :gross=>20000, 
        :fees=>0, 
        :refunds=>0, 
        :liquid=>20000, 
        :currency=>"BRL"
    }, 
    installment_count=1, 
    statement_descriptor="Some Store", 
    funding_instrument={
        :boleto=>{
            :expiration_date=>"2019-04-08", 
            :line_code=>"00000.00009 01014.051005 00000.787176 7 72370000001000", 
            :logo_uri=>"https://some.logo.com/some_image.jpg", 
            :instruction_lines=>{
                :first=>"Some instruction 1", 
                :second=>"Some instruction 2", 
                :third=>"Some instruction 3"
            }
        }, 
        :method=>"BOLETO"
    }, 
    fees=[
        {
            :type=>"TRANSACTION", 
            :amount=>0
        }
    ], 
    events=[
        {
            :type=>"PAYMENT.CREATED", 
            :created_at=>"2019-04-03T16:21:31.504-03"
        }, 
        {
            :type=>"PAYMENT.WAITING", 
            :created_at=>"2019-04-03T16:21:31.504-03"
        }
    ], 
    receivers=[
        {
            :moip_account=>{
                :id=>"MPA-000000", 
                :login=>"some@email.com.br", 
                :fullname=>"full name"
            }, 
            :type=>"PRIMARY", 
            :amount=>{
                :total=>20000, 
                :currency=>"BRL", 
                :fees=>0, 
                :refunds=>0
            }, 
            :fee_payor=>true
        }
    ], 
    _links={
        :self=>{
            :href=>"https://sandbox.moip.com.br/v2/payments/PAY-000000"
        }, 
        :order=>{
            :href=>"https://sandbox.moip.com.br/v2/orders/ORD-000000", 
            :title=>"ORD-000000"
        }, 
        :pay_boleto=>{
            :print_href=>"https://sandbox.moip.com.br/v2/boleto/BOL-000000/print", 
            :redirect_href=>"https://sandbox.moip.com.br/v2/boleto/BOL-000000"
        }
    }, 
    created_at="2019-04-03T16:21:31.500-03", 
    updated_at="2019-04-03T16:21:31.500-03"

```
