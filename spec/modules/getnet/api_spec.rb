require 'rspec'
require 'pry'

RSpec.describe Checkout::Getnet::Api do
  before(:each) do
    @api = Checkout::Getnet::Api.new
  end

  it 'should generate auth token' do
    response = @api.access_token

    expect(response['access_token'].empty?).to be_falsey
    expect(response['token_type']).to eq 'Bearer'
  end

  context 'credit card' do
    before(:each) do
      @access_token = @api.access_token['access_token']
      @api.update_access_token @access_token
    end

    it 'should generate credit card token number' do
      credit_card_number = '4111111111111111'
      response = @api.credit_card_token(credit_card_number)
      expect(response['number_token'].empty?).to be_falsey
    end
  end


end