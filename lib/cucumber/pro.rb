require 'logger'
require 'cucumber/pro/formatter'
require 'cucumber/pro/web_socket/session'
require 'cucumber/pro/errors'

module Cucumber
  module Pro
    class << self
      def new(runtime, output, options)
        create_logger(output)

        working_copy = Scm::WorkingCopy.detect

        if should_publish
          working_copy.check_clean
          session = WebSocket::Session.new(url, logger, timeout: config.timeout)
        else
          session = WebSocket::NullSession.new
        end

        Formatter.new(session, working_copy)
      end

      def configure
        yield config
      end

      def config
        @config ||= Config.new
      end

      private

      attr_reader :logger
      private :logger

      def url
        config.url + "?token=#{token}"
      end

      def create_logger(output)
        @logger = config.logger || Logger.new(output)
      end

      def token
        config.token
      end

      def should_publish
        config.should_publish
      end
    end

    class Config
      attr_accessor :url, :logger, :token, :should_publish, :timeout, :build_number
    end

    # Default config
    configure do |config|
      config.url     = ENV['CUCUMBER_PRO_RESULTS_URL'] || 'wss://results.cucumber.pro/ws'
      config.token   = ENV['CUCUMBER_PRO_TOKEN']
      config.build_number = ENV['BUILD_NUMBER'] || ENV['CIRCLE_BUILD_NUM'] || ENV['TRAVIS_JOB_NUMBER'] || ENV['bamboo.buildNumber'] || ENV['CI_BUILD_NUMBER']
      config.should_publish = config.token && (config.build_number || ENV['CI'])
      config.timeout = 5
      if file = ENV['CUCUMBER_PRO_LOG_FILE']
        config.logger = Logger.new(file)
      end
    end

  end
end
