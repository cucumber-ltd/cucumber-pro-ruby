require 'logger'
require 'cucumber/pro/formatter'
require 'cucumber/pro/web_socket/session'
require 'cucumber/pro/errors'

module Cucumber
  module Pro

    class << self
      def new(runtime, output, options)
        create_logger(output)
        session = WebSocket::Session.new(url, logger, timeout: config.timeout)
        Formatter.new(session)
      end

      def configure
        yield config
      end

      private

      attr_reader :logger
      private :logger

      def config
        @config ||= Config.new
      end

      def url
        config.url + "?token=#{token}"
      end

      def create_logger(output)
        @logger = config.logger || Logger.new(output)
      end

      def token
        result = (config.token || '')
        raise(Error::MissingToken.new) if result.empty?
        result
      end
    end

    class Config
      attr_accessor :url, :logger, :token, :timeout
    end

    # Default config
    configure do |config|
      config.url    = ENV['CUCUMBER_PRO_URL'] || 'wss://results.cucumber.pro/ws'
      config.token  = ENV['CUCUMBER_PRO_TOKEN']
      ENV['cucumber_pro_log_path'].tap do |path|
        config.logger = Logger.new(path) if path
      end
      config.timeout = 5
    end

  end
end
