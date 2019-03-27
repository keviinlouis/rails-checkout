require 'rspec'
require 'pry'
RSpec.describe Checkout::Wirecard::Api do
  before(:each) do
    @gateway = Checkout::Wirecard::Api.new(Checkout::Wirecard::Auth.new :development)

    webhooks = @gateway.list_webhooks

    webhooks.each do |w|
      @gateway.remove_webhook Checkout::Wirecard::Webhook.new(
        w["target"],
        w["events"]
      )
    end
  end

  it 'should create webhook' do
    events = [
      'ORDER.*'
    ]
    url = 'https://some_path.com.br'
    webhook = Checkout::Wirecard::Webhook.new(
      url,
      events
    )

    wirecard_response = @gateway.create_webhook webhook

    expect(wirecard_response["events"] - events).to eq []
    expect(wirecard_response["target"]).to eq url
    expect(wirecard_response["media"]).to eq "WEBHOOK"
  end

  it 'should return false if already has the same webhook' do
    events = [
      'ORDER.*'
    ]
    url = 'https://some_path.com.br'
    webhook = Checkout::Wirecard::Webhook.new(
      url,
      events
    )

    @gateway.create_webhook webhook
    wirecard_response = @gateway.create_webhook webhook

    expect(wirecard_response).to be_falsey
  end
end