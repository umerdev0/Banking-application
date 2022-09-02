# frozen_string_literal: true

# Load the Rails application.
require_relative 'application'

env_file = Rails.root.join('config/environment_variables.yml').to_s
if File.exist?(env_file)
  YAML.load_file(env_file)[Rails.env].each do |key, value|
    ENV[key.to_s] = value
  end
end

# Initialize the Rails application.
Rails.application.initialize!
