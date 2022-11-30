require "spec_helper"
require "rack/test"
require "logger"

require "rack/logstasher"

describe Rack::Logstasher::Logger do
  include Rack::Test::Methods

  describe "parameters" do
    def app
      Rack::Logstasher::Logger.new(
        proc { |_env| [200, {}, ["Inner app response"]] },
        Logger.new(tmp_logfile_path),
      )
    end

    it "adds request details to the logfile" do
      get "/foo?bar=baz"

      log_details = JSON.parse(last_log_line)

      expect(log_details["method"]).to eq("GET")
      expect(log_details["path"]).to eq("/foo")
      expect(log_details["query_string"]).to eq("bar=baz")
      expect(log_details["request"]).to eq("GET /foo?bar=baz HTTP/1.0")
    end

    it "adds a tag of 'request'" do
      get "/foo?bar=baz"

      log_details = JSON.parse(last_log_line)
      expect(log_details["tags"]).to eq(%w[request])
    end
  end

  describe "duration" do
    def app
      Rack::Logstasher::Logger.new(
        proc do |_env|
          sleep 0.1
          [200, {}, ["Inner app response"]]
        end,
        Logger.new(tmp_logfile_path),
      )
    end

    it "logs request duration" do
      get "/foo"

      log_details = JSON.parse(last_log_line)
      expect(log_details["duration"]).to be_within(5).of(100)
    end
  end

  describe "HTTP headers" do
    context "when there are extra request headers" do
      let(:extra_request_headers) { {} }

      def app
        Rack::Logstasher::Logger.new(
          proc { |_env| [200, {}, ["Inner app response"]] },
          Logger.new(tmp_logfile_path),
          extra_request_headers: extra_request_headers,
        )
      end

      it "adds specified extra request headers to the log under the given key" do
        extra_request_headers["foo"] = "header_foo"
        get "/something", {}, { "HTTP_FOO" => "bar" }

        log_details = JSON.parse(last_log_line)

        expect(log_details["header_foo"]).to eq("bar")
      end

      it "does not add the key if the header is missing" do
        extra_request_headers["foo"] = "header_foo"
        get "/something"

        log_details = JSON.parse(last_log_line)

        expect(log_details).not_to have_key("header_foo")
      end

      it "handles dashes in header name" do
        extra_request_headers["Varnish-Id"] = "varnish_id"
        get "/something", {}, { "HTTP_VARNISH_ID" => "1234" }

        log_details = JSON.parse(last_log_line)

        expect(log_details["varnish_id"]).to eq("1234")
      end
    end

    context "when there are extra response headers" do
      let(:extra_response_headers) { {} }
      let(:inner_response_headers) { {} }

      def app
        Rack::Logstasher::Logger.new(
          proc do |_env|
            headers = inner_response_headers
            [200, headers, ["Inner app response"]]
          end,
          Logger.new(tmp_logfile_path),
          extra_response_headers: extra_response_headers,
        )
      end

      it "adds specified extra response headers to the log under the given key" do
        extra_response_headers["foo"] = "header_foo"
        inner_response_headers["foo"] = "bar"
        get "/something"

        log_details = JSON.parse(last_log_line)

        expect(log_details["header_foo"]).to eq("bar")
      end

      it "does not add the key if the header is missing" do
        extra_response_headers["foo"] = "header_foo"
        get "/something"

        log_details = JSON.parse(last_log_line)

        expect(log_details).not_to have_key("header_foo")
      end

      it "handles dashes in header name" do
        extra_response_headers["X-Cache"] = "cache_status"
        inner_response_headers["X-Cache"] = "MISS"
        get "/something"

        log_details = JSON.parse(last_log_line)

        expect(log_details["cache_status"]).to eq("MISS")
      end
    end
  end
end
