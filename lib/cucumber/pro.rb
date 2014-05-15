require 'logger'
require 'cucumber/pro/formatter'
require 'cucumber/pro/web_socket_session'
require 'cucumber/pro/version'

module Cucumber
  module Pro

    class << self
      def new(*)
        url = config.url + "?token=#{config.token}"
        session = WebSocketSession.new(url, config.logger)
        Formatter.new(session)
      end

      def configure
        yield config
      end

      private

      def config
        @config ||= Config.new
      end
    end

    class Config
      attr_accessor :url, :logger, :token
    end

    # Default config
    configure do |config|
      config.url    = 'wss://results.cucumber.pro/ws'
      config.logger = Logger.new(ENV['cucumber_pro_log_path'] || STDOUT)
      config.token  = ENV['CUCUMBER_PRO_TOKEN']
    end

  end
end


