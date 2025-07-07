# COAR Notify

A Ruby implementation of the [COAR Notify protocol](https://coar-notify.net/) for scholarly communication notifications.

This library provides a complete Ruby implementation of all COAR Notify patterns, allowing you to:

- Send notifications to COAR Notify inboxes
- Receive and process COAR Notify notifications
- Validate notification patterns
- Create custom notification patterns

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'coarnotify'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install coarnotify

## Usage

### Creating and Sending Notifications

```ruby
require 'coarnotify'

# Create a client
client = Coarnotify.client(inbox_url: "https://example.com/inbox")

# Create a notification pattern
notification = Coarnotify::Patterns::RequestReview.new

# Set up the notification properties
notification.origin = Coarnotify::Core::Notify::NotifyService.new
notification.origin.id = "https://overlay-journal.com"
notification.origin.inbox = "https://overlay-journal.com/inbox"

notification.target = Coarnotify::Core::Notify::NotifyService.new
notification.target.id = "https://review-service.com"
notification.target.inbox = "https://review-service.com/inbox"

notification.object = Coarnotify::Patterns::RequestReviewObject.new
notification.object.id = "https://research-organisation.org/repository/preprint/201203/421/"
notification.object.cite_as = "https://doi.org/10.5555/12345680"

# Send the notification
response = client.send(notification)
puts "Notification sent with status: #{response.action}"
```

### Receiving Notifications

```ruby
require 'coarnotify'

# Create a service binding
class MyServiceBinding < Coarnotify::Server::COARNotifyServiceBinding
  def notification_received(notification)
    puts "Received notification of type: #{notification.class}"
    
    # Process the notification based on its type
    case notification
    when Coarnotify::Patterns::RequestReview
      handle_review_request(notification)
    when Coarnotify::Patterns::Accept
      handle_acceptance(notification)
    # ... handle other patterns
    end
    
    # Return a receipt
    Coarnotify::Server::COARNotifyReceipt.new(
      Coarnotify::Server::COARNotifyReceipt::CREATED,
      "https://example.com/notifications/123"
    )
  end
  
  private
  
  def handle_review_request(notification)
    # Your review request handling logic
  end
  
  def handle_acceptance(notification)
    # Your acceptance handling logic
  end
end

# Create a server
server = Coarnotify.server(MyServiceBinding.new)

# In your web framework (e.g., Rails, Sinatra), handle incoming requests:
begin
  receipt = server.receive(request.body)
  # Return appropriate HTTP response based on receipt.status
rescue Coarnotify::Server::COARNotifyServerError => e
  # Return error response with status e.status and message e.message
end
```

### Creating Patterns from JSON

```ruby
# From JSON string
json_data = '{"@context": [...], "type": "Accept", ...}'
notification = Coarnotify.from_json(json_data)

# From hash
hash_data = { "@context" => [...], "type" => "Accept", ... }
notification = Coarnotify.from_hash(hash_data)
```

## Supported Patterns

This library supports all COAR Notify patterns:

- **Accept** - Accept a previous notification
- **Reject** - Reject a previous notification  
- **TentativelyAccept** - Tentatively accept a previous notification
- **TentativelyReject** - Tentatively reject a previous notification
- **RequestReview** - Request a review of a resource
- **RequestEndorsement** - Request an endorsement of a resource
- **AnnounceReview** - Announce a review of a resource
- **AnnounceEndorsement** - Announce an endorsement of a resource
- **AnnounceRelationship** - Announce a relationship between resources
- **AnnounceServiceResult** - Announce the result of a service
- **UndoOffer** - Undo a previous offer
- **UnprocessableNotification** - Indicate a notification could not be processed

## Architecture

The library is organized into several modules:

- **Core** - Base classes and ActivityStreams 2.0 implementation
- **Patterns** - All COAR Notify pattern implementations
- **Client** - HTTP client for sending notifications
- **Server** - Server framework for receiving notifications
- **Factory** - Factory for creating pattern objects from data
- **Validate** - Validation framework
- **Http** - HTTP layer abstraction

## Validation

All patterns include comprehensive validation:

```ruby
notification = Coarnotify::Patterns::Accept.new
begin
  notification.validate
  puts "Notification is valid"
rescue Coarnotify::ValidationError => e
  puts "Validation errors: #{e.errors}"
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/CottageLabs/coarnotifyrb](https://github.com/coar-notify/coarnotifyrb).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Compatibility

This Ruby implementation maintains 100% functional compatibility with the Python coarnotifypy library, ensuring consistent behavior across different language implementations of the COAR Notify protocol.
