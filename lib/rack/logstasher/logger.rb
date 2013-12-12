require 'rack/commonlogger'
require 'logstash/event'

module Rack
  module Logstasher
    class Logger < Rack::CommonLogger
      def initialize(app, logger)
        super(app, logger)
      end

      private

      def log(env, status, header, began_at)
        now = Time.now

        data = {
          :method => env["REQUEST_METHOD"],
          :path => env["PATH_INFO"],
          :status => status.to_i,
          :duration => duration_in_ms(began_at, now).round(2),
          :remote_addr => env['REMOTE_ADDR'],
          :parameters => env["QUERY_STRING"],
          :request => request_line(env),
          :length => extract_content_length(header)
        }

        event = LogStash::Event.new('@fields' => data, '@tags' => ['request'])
        msg = event.to_json + "\n"
        if @logger.respond_to?(:write)
          @logger.write(msg)
        else
          @logger << msg
        end
      end

      def duration_in_ms(began, ended)
        (ended - began) * 1000
      end

      def request_line(env)
        line = "#{env["REQUEST_METHOD"]} #{env["SCRIPT_NAME"]}#{env['PATH_INFO']}"
        line << "?#{env["QUERY_STRING"]}" if env["QUERY_STRING"] and ! env["QUERY_STRING"].empty?
        line << " #{env["SERVER_PROTOCOL"]}"
        line
      end

    end # Logger
  end
end
