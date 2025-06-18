# frozen_string_literal: true

require "bundler/setup"

# Load the library components individually to avoid circular dependency issues
require "coarnotify/version"
require "coarnotify/exceptions"
require "coarnotify/validate"
require "coarnotify/core/activity_streams2"
require "coarnotify/core/notify"
require "coarnotify/http"
require "coarnotify/patterns/accept"
require "coarnotify/patterns/announce_endorsement"
require "coarnotify/patterns/announce_relationship"
require "coarnotify/patterns/announce_review"
require "coarnotify/patterns/announce_service_result"
require "coarnotify/patterns/reject"
require "coarnotify/patterns/request_endorsement"
require "coarnotify/patterns/request_review"
require "coarnotify/patterns/tentatively_accept"
require "coarnotify/patterns/tentatively_reject"
require "coarnotify/patterns/undo_offer"
require "coarnotify/patterns/unprocessable_notification"
require "coarnotify/factory"
require "coarnotify/client"
require "coarnotify/server"
require "coarnotify"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
