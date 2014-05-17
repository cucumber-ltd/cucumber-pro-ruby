require 'logger'
require 'cucumber/pro/formatter'
require 'cucumber/pro/web_socket_session'
require 'cucumber/pro/version'

module Cucumber
  module Pro

    class << self
      def new(*)
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

      def url
        token = config.token || raise(Error::MissingToken.new)
        config.url + "?token=#{token}"
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

    module Error
      AccessDenied = Class.new(StandardError) {
        def initialize
          super "Access denied."
        end
      }

      MissingToken = Class.new(StandardError) {
        def initialize
          super "Missing access token. Please visit https://app.cucumber.pro/api-token for instructions."
        end
      }
    end

  end
end


