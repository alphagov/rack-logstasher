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
      fields = log_details['@fields']

      expect(fields['method']).to eq('GET')
      expect(fields['path']).to eq('/foo')
      expect(fields['parameters']).to eq('bar=baz')
      expect(fields['request']).to eq('GET /foo?bar=baz ') # env['SERVER_PROTOCOL'] is not set under rack-test
    end

    it "should add request duration" do
      @sleep_time = 0.1
      get "/foo"

      log_details = JSON.parse(last_log_line)
      fields = log_details['@fields']

      expect(fields['duration']).to be_within(5).of(100)
    end

    it "should add a tag of 'request'" do
      get "/foo?bar=baz"

      log_details = JSON.parse(last_log_line)
      expect(log_details['@tags']).to eq(['request'])
    end

    describe "adding extra headers to the log" do
      before :each do
        @extra_headers = {}
      end
      def app
        Rack::Logstasher::Logger.new(
          proc {|env|
            sleep @sleep_time if @sleep_time
            [200, {}, ["Inner app response"]]
          },
          Logger.new(tmp_logfile_path),
          :extra_headers => @extra_headers
        )
      end

      it "should add specified extra headers to the log under the given key" do
        @extra_headers["foo"] = "header_foo"
        get "/something", {}, {"HTTP_FOO" => "bar"}

        log_details = JSON.parse(last_log_line)
        fields = log_details['@fields']

        expect(fields['header_foo']).to eq('bar')
      end

      it "should not add the key if the header is missing" do
        @extra_headers["foo"] = "header_foo"
        get "/something"

        log_details = JSON.parse(last_log_line)
        fields = log_details['@fields']

        expect(fields).not_to have_key('header_foo')
      end

      it "should handle dashes in header name" do
        @extra_headers["Varnish-Id"] = "varnish_id"
        get "/something", {}, {"HTTP_VARNISH_ID" => "1234"}

        log_details = JSON.parse(last_log_line)
        fields = log_details['@fields']

        expect(fields['varnish_id']).to eq('1234')
      end
    end
  end
end
