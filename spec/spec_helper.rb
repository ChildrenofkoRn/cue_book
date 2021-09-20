require 'rspec'
require 'factory_bot'

RSpec.configure do |config|

  config.expose_dsl_globally = true

  # config.use_transactional_fixtures = true

  # Use color in STDOUT
  config.color_mode = :on

  # Use color not only in STDOUT but also in pagers and files
  config.tty = true

  # Use the specified formatter
  config.formatter = :documentation # :progress, :html, :textmate

  config.before(:each) do

  end

  config.after(:each) do

  end

  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    FactoryBot.find_definitions
  end
end

def load_class(file)
  require File.expand_path("cue_error")
  klass = File.basename(file).gsub('_spec','')
  require File.expand_path("#{klass}")
end
