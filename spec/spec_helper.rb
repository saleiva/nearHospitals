$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rspec'
require 'yaml'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.before(:all) do
    CartoDB::Settings = YAML.load_file(Rails.root.join('/config/cartodb_config.yml'))

    @cartodb = CartoDB::Client.new
  end

  config.before(:each) do
    @cartodb.drop_table 'al_hospital_demo'
  end

  config.after(:all) do
    @cartodb.drop_table 'al_hospital_demo'
  end
end
