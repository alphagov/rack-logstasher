require 'logstash/event'

begin
  require 'rack/common_logger'
rescue LoadError
  require 'rack/commonlogger'
end

module Rack
  module Logstasher
    class Logger < Rack::CommonLogger
      def initialize(app, logger, opts = {})
        super(app, logger)
        @extra_request_headers = opts[:extra_request_headers] || {}
        @extra_response_headers = opts[:extra_response_headers] || {}
      end

      private

      def log(env, status, response_headers, began_at)
        now = Time.now

        data = {
          :method => env["REQUEST_METHOD"],
          :path => env["PATH_INFO"],
          :query_string => env["QUERY_STRING"],
          :status => status.to_i,
          :duration => duration_in_ms(began_at, now).round(2),
          :remote_addr => env['REMOTE_ADDR'],
          :request => request_line(env),
          :length => extract_content_length(response_headers)
        }

        @extra_request_headers.each do |header, log_key|
          env_key = "HTTP_#{header.upcase.gsub('-', '_')}"
          if env[env_key]
            data[log_key] = env[env_key]
          end
        end

        @extra_response_headers.each do |header, log_key|
          if response_headers[header]
            data[log_key] = response_headers[header]
          end
        end

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
