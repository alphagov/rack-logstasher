# Rack::Logstasher

Rack middleware to log requests in logstash json event format

## Installation

Add this line to your application's Gemfile:

    gem 'rack-logstasher'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rack-logstasher

## Usage

Add this to the middleware stack.  e.g.

    use Rack::Logstasher::Logger, Logger.new("/path/to/logfile.json.log")

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
