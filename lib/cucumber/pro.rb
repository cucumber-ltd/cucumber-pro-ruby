require 'logger'
require 'cucumber/pro/formatter'
module Cucumber
  module Pro
    def self.new(*args)
      logger = Logger.new(ENV['cucumber_pro_log_path'] || STDOUT)
      host = 'localhost'
      port = 5000
      session = WebSocketSession.new(host, port, logger)
      Formatter.new(session)
    end
  end
end
