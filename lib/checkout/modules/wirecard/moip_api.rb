class MoipApi
  attr_accessor :auth, :client, :api, :access_token

  def initialize(token_oauth=nil)
    return if token_oauth.nil?
    @access_token = token_oauth
    @auth = Moip2::Auth::OAuth.new(token_oauth)
    @client = Moip2::Client.new(Rails.env.production? ? "production" : "development", auth)
    @api = Moip2::Api.new(@client)
    self
  end

  def init
    auth = Moip2::Auth::Basic.new(Rails.application.secrets.moip['api_token'], Rails.application.secrets.moip['api_key'])
    @client = Moip2::Client.new(Rails.env, auth)
    @api = Moip2::Api.new(@client)
    self
  end

  def items_params(line_items)
    line_items.map do |line_item|
      {
        product: line_item.product.title,
        quantity: line_item.quantity,
        # detail: "Mais info...",
        price: (line_item.unit_price.to_f*100).to_i
      }
    end
  end

  def customer_params(order)
    customer = order.customer
    address = order.shipping_address
    phone = customer.phone.try(:scan, /\d+/)
    phone = phone.is_a?(Array) ? phone[1..-1].join : nil
    {
      own_id: customer.id,
      fullname: customer.identification,
      email: customer.email,
      taxDocument: {
        type: customer.company? ? 'CNPJ' : 'CPF',
        number: customer.document
      },
      shippingAddress: {
        zipCode: address.postal_code.sub('-',''),
        street: address.street_name,
        streetNumber: address.number,
        complement: address.complement,
        city: address.city,
        district: address.neighborhood,
        state: address.state,
        country: "BRA"
      },
      phone: {
        countryCode: "55",
        areaCode: customer.phone.try(:match, /\d+/).try(:to_s),
        number: phone
      }
    }
  end

  def receivers_params(mine_order)
    if mine_order.melhor_envio_info.try(:shipping_id?)
      [store_keeper_receiver_params(mine_order)] +
      [mine_receiver_params(mine_order)] +
      [melhor_envio_receiver_params(mine_order)]
    else
      if mine_order.store.commission > 0
        return [
          store_keeper_receiver_params(mine_order),
          mine_receiver_params(mine_order)
        ]
      end

      [store_keeper_receiver_params(mine_order)]
    end
  end

  def mine_receiver_params(mine_order)
    commission = mine_order.store.commission.to_f

    {
      type: 'SECONDARY',
      feePayor: false,
      moipAccount: {
        id: self.class.secrets['mine_id'],
      },
      amount: {
        percentual: commission
      }
    }
  end

  def melhor_envio_receiver_params(mine_order)
    shipping = mine_order.shipping_price_cents

    {
      type: 'SECONDARY',
      feePayor: false,
      moipAccount: {
        id: self.class.secrets['melhor_envio_id'],
      },
      amount: {
        fixed: shipping
      }
    }
  end

  def store_keeper_receiver_params(mine_order)
    total_price = mine_order.total_price
    commission = total_price * (mine_order.store.commission/100)

    params = {
      type: 'PRIMARY',
      feePayor: true,
      moipAccount: {
        id: mine_order.store.moip_account_id
      }
    }

    params
  end

  def self.account_email(store)
    response = RestClient.get(
      "https://#{sandbox_subdomain}.moip.com.br/v2/accounts/#{store.moip_account_id}",
      { Authorization: "OAuth #{store.moip_access_token}" }
    )
    JSON.parse(response).fetch('email', {}).fetch('address')
  rescue JSON::ParserError
    response
  end

  def self.moip_order_id(order_id, moip_access_token)
    transaction_id = Order.find(order_id).payments.order(:created_at)
      .last.info.transaction_id
    response = RestClient.get(
      "https://#{sandbox_subdomain}.moip.com.br/v2/payments/#{transaction_id}",
      { Authorization: "OAuth #{moip_access_token}" }
    )
    JSON.parse(response).fetch('_links', {}).fetch('order', {}).fetch('title', {})
  rescue JSON::ParserError
    response
  end

  def create_payment(moip_order_id, params)
    @api.payment.create moip_order_id, params
  end

  def create_order(mine_order, installments=1)
    @api.order.create({
      own_id: mine_order.token,
      items: items_params(mine_order.line_items),
      customer: customer_params(mine_order),
      receivers: receivers_params(mine_order),
      amount: {
        subtotals: {
          addition: ((self.class.order_price_with_advance_taxes(mine_order, installments) - mine_order.total_price.to_f)*100).to_i,
          shipping: (mine_order.shipping_price.to_f*100).to_i,
          discount: (mine_order.total_discount.to_f*100).to_i
        }
      }
    })
  end

  def payment_status(payment)
    moip_payment_id = payment.info.transaction_id
    moip_access_token = payment.order.store.moip_access_token
    response = RestClient.get(
      "https://#{MoipApi.sandbox_subdomain}.moip.com.br/v2/payments/#{moip_payment_id}",
      { Authorization: "OAuth #{moip_access_token}" }
    )
    JSON.parse(response)['status']
  rescue JSON::ParserError
    response
  end

  def orders
    response = RestClient.get("https://#{MoipApi.sandbox_subdomain}.moip.com.br/v2/orders", {
      Authorization: "OAuth #{access_token}", content_type: :json
    })

    JSON.parse(response)['orders']
  end

  def order(moip_id)
    response = RestClient.get("https://#{MoipApi.sandbox_subdomain}.moip.com.br/v2/orders/#{moip_id}", {
      Authorization: "OAuth #{access_token}", content_type: :json
    })

    JSON.parse(response)
  end

  def self.oauth_url(store, release_days)
    callback_url = CGI.escape "#{Rails.application.secrets.moip['callback_url']}?store_id=#{store.id}&release_days=#{release_days}&custom_app=#{release_days == 'custom'}"
    app_id = Rails.application.secrets.moip['release_days'][release_days.try(:to_s)]['app_id']
    "https://connect#{connect_sandbox}.moip.com.br/oauth/authorize?response_type=code&client_id=#{app_id}&redirect_uri=#{callback_url}&scope=RECEIVE_FUNDS,DEFINE_PREFERENCES,MANAGE_ACCOUNT_INFO"
  end

  def self.refresh_tokens(refresh_token)
    response = RestClient.post "https://connect#{connect_sandbox}.moip.com.br/oauth/token",
      {
        grant_type: 'refresh_token',
        refresh_token: refresh_token
      }, basic_auth
    response = JSON.parse response rescue response
    response.extract!('refresh_token', 'access_token')
  end

  def self.first_tokens(code, store, custom_app=false)
    release_days = store.payment_settings.moip_days_release_money
    app_id = nil
    app_secret = nil
    if custom_app == 'true'
      app_id = secrets['release_days']['custom']['app_id']
      app_secret = secrets['release_days']['custom']['app_secret']
    else
      app_id = secrets['release_days'][release_days.try(:to_s)]['app_id']
      app_secret = secrets['release_days'][release_days.try(:to_s)]['app_secret']
    end
    response = RestClient.post "https://connect#{connect_sandbox}.moip.com.br/oauth/token",
      {
        client_id: app_id,
        client_secret: app_secret,
        grant_type: 'authorization_code',
        code: code,
        redirect_uri: secrets['callback_url']
      }, basic_auth
    response = JSON.parse response rescue response
    response.extract!('refresh_token', 'access_token', 'moipAccount')
  end

  def self.resend_webhook(resource_id)
    RestClient.post "https://#{sandbox_subdomain}.moip.com.br/v2/webhooks/",
      { resourceId: resource_id }, basic_auth
  end

  def self.secrets
    Rails.application.secrets.moip
  end

  def self.basic_auth
    { :Authorization => "Basic #{Base64.encode64("#{secrets['api_token']}:#{secrets['api_key']}").gsub("\n", '')}" }
  end

  def self.sandbox_subdomain
    Rails.env.production? ? 'api' : 'sandbox'
  end

  # Call only once to start receiving payment notifications
  def self.setup_webhook_minestore(access_token)
    RestClient.post "https://#{sandbox_subdomain}.moip.com.br/v2/preferences/notifications", {
      events: [
        "PAYMENT.*"
      ],
      target: secrets['webhook_url'],
      media: "WEBHOOK"
    }.to_json, { Authorization: "OAuth #{access_token}", content_type: :json }
  end

  def self.setup_webhook_melhor_envio(access_token)
    RestClient.post "https://#{sandbox_subdomain}.moip.com.br/v2/preferences/notifications", {
      events: [
        "ORDER.REVERTED"
      ],
      target: secrets['webhook_melhor_envio'],
      media: "WEBHOOK"
    }.to_json, { Authorization: "OAuth #{access_token}", content_type: :json }
  end

  def self.list_webhooks(access_token)
    JSON.parse(RestClient.get("https://#{sandbox_subdomain}.moip.com.br/v2/preferences/notifications", {
      Authorization: "OAuth #{access_token}", content_type: :json
    }))
  end

  def self.connect_sandbox
    Rails.env.production? ? '' : '-sandbox'
  end

  def self.order_price_with_advance_taxes(order, installments=1)
    store_settings = order.store.payment_settings
    return order.total_price.to_f unless store_settings.forward_taxes
    store_relase_days = store_settings.moip_days_release_money.to_s
    taxes = secrets['release_days'][store_relase_days]['advance_taxes']
    order.total_price.to_f * 1/(1-taxes[installments.to_s].to_f)
  end
end
