require "bundler/setup"
require "checkout"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  Checkout.configure do |c|
    c.wirecard = {
      key: '5PB0KRQECQDAQL3WO9J3DS5FFYJBA8DNKPTLW9YI',
      token: 'LVRVXDZ3EPTH8VXK9CZN0OBX64PF9SW5',
      webhook_url: ''
    }
  end
end
