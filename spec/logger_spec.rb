require 'spec_helper'
require 'rack/test'
require 'logger'

require 'rack/logstasher'

describe "Logger" do
  include Rack::Test::Methods

  describe "adding request details to the logfile" do
    def app
      Rack::Logstasher::Logger.new(
        proc {|env|
          sleep @sleep_time if @sleep_time
          [200, {}, ["Inner app response"]]
        },
        Logger.new(tmp_logfile_path)
      )
    end

    it "should add request details to the logfile" do
      get "/foo?bar=baz"

      log_details = JSON.parse(last_log_line)

      expect(log_details['method']).to eq('GET')
      expect(log_details['path']).to eq('/foo')
      expect(log_details['query_string']).to eq('bar=baz')
      expect(log_details['request']).to eq('GET /foo?bar=baz ') # env['SERVER_PROTOCOL'] is not set under rack-test
    end

    it "should add request duration" do
      @sleep_time = 0.1
      get "/foo"

      log_details = JSON.parse(last_log_line)

      expect(log_details['duration']).to be_within(5).of(100)
    end

    it "should add a tag of 'request'" do
      get "/foo?bar=baz"

      log_details = JSON.parse(last_log_line)
      expect(log_details['tags']).to eq(['request'])
    end

    describe "adding extra headers to the log" do
      before :each do
        @extra_request_headers = {}
        @extra_response_headers = {}
      end
      def app
        Rack::Logstasher::Logger.new(
          proc {|env|
            headers = @inner_response_headers || {}
            [200, headers, ["Inner app response"]]
          },
          Logger.new(tmp_logfile_path),
          :extra_request_headers => @extra_request_headers,
          :extra_response_headers => @extra_response_headers
        )
      end

      context "extra request headers" do
        it "should add specified extra request headers to the log under the given key" do
          @extra_request_headers["foo"] = "header_foo"
          get "/something", {}, {"HTTP_FOO" => "bar"}

          log_details = JSON.parse(last_log_line)

          expect(log_details['header_foo']).to eq('bar')
        end

        it "should not add the key if the header is missing" do
          @extra_request_headers["foo"] = "header_foo"
          get "/something"

          log_details = JSON.parse(last_log_line)

          expect(log_details).not_to have_key('header_foo')
        end

        it "should handle dashes in header name" do
          @extra_request_headers["Varnish-Id"] = "varnish_id"
          get "/something", {}, {"HTTP_VARNISH_ID" => "1234"}

          log_details = JSON.parse(last_log_line)

          expect(log_details['varnish_id']).to eq('1234')
        end
      end

      context "extra response headers" do
        it "should add specified extra response headers to the log under the given key" do
          @extra_response_headers["foo"] = "header_foo"
          @inner_response_headers = {"Foo" => "bar"}
          get "/something"

          log_details = JSON.parse(last_log_line)

          expect(log_details['header_foo']).to eq('bar')
        end

        it "should not add the key if the header is missing" do
          @extra_response_headers["foo"] = "header_foo"
          get "/something"

          log_details = JSON.parse(last_log_line)

          expect(log_details).not_to have_key('header_foo')
        end

        it "should handle dashes in header name" do
          @extra_response_headers["X-Cache"] = "cache_status"
          @inner_response_headers = {"X-Cache" => "MISS"}
          get "/something"

          log_details = JSON.parse(last_log_line)

          expect(log_details['cache_status']).to eq('MISS')
        end

        it "should match header in a case-insensitive fashion" do
          @extra_response_headers["X-CacHe"] = "cache_status"
          @inner_response_headers = {"x-cAche" => "MISS"}
          get "/something"

          log_details = JSON.parse(last_log_line)

          expect(log_details['cache_status']).to eq('MISS')
        end
      end
    end
  end
end
