require 'faye/websocket'
require 'json'

module FakeResultsService
  class << self
    def messages
      @messages ||= []
    end

    def reset
      @messages = nil
    end

    def logger
      $logger
    end
  end

  logger = self.logger

  app = lambda do |env|
    logger.debug [:server, :starting]
    ws = Faye::WebSocket.new(env)

    ws.on :open do |event|
      logger.debug [:server, :open]
    end

    ws.on :message do |event|
      logger.debug [:server, :message, event.data]
      FakeResultsService.messages << JSON.parse(event.data)
      ws.send 'ok'
    end

    ws.on :close do |event|
      logger.debug [:server, :close]
      EM.stop_event_loop
      ws = nil
    end

    # Return async Rack response
    ws.rack_response
  end

  require 'thin'
  require 'rack'
  require 'eventmachine'
  Faye::WebSocket.load_adapter 'thin'
  Thin::Logging.logger = logger
  $em = Thread.new do
    begin
      EM.run do
        thin = Rack::Handler.get('thin')
        thin.run app, :Port => 5001
        trap("INT") { exit }
      end
    rescue => exception
      logger.fatal(exception)
      $stderr.puts exception, exception.backtrace
      exit 1
    end
  end

  loop until EM.reactor_running?
end

if respond_to?(:Before)
  # Cucumber mode
  Before { FakeResultsService.reset }
  After { FakeResultsService.logger.debug [:server, :messages, FakeResultsService.messages] }
else
  # Standalone (manual test) mode
  $em.join
end
