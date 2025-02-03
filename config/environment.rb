# Load the Rails application.
require_relative "application"

# Initialize the Rails application.
Rails.application.initialize!
# Use tag or commit hash as version string; sub removes tag from tag-hash output
APP_VERSION = `git describe --always`.sub(/.*-g/, '') unless defined? APP_VERSION