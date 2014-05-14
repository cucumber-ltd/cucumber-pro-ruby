require 'logger'
require 'cucumber/pro/formatter'
require 'cucumber/pro/web_socket_session'

module Cucumber
  module Pro

    class << self
      def new(*)
        session = WebSocketSession.new(config.url, config.logger)
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
      attr_accessor :url, :logger
    end

    # Default config
    configure do |config|
      config.url = 'ws://metarepo.cucumber.pro/ws'
      config.logger = Logger.new(ENV['cucumber_pro_log_path'] || STDOUT)
    end

  end
end


