require 'faye/websocket'
require 'json'

module FakeResultsService
  PORT = 5000
  VALID_TOKEN = 'valid-token'

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

  class SocketApp 
    def initialize(logger)
      @logger = logger
    end

    def call(env)
      request = Rack::Request.new(env)
      params = request.params
      return [401, [], {}] unless params['token'] == VALID_TOKEN

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

      ws.on :error do |event|
        logger.debug [:server, :error, event.code, event.reason]
      end

      ws.on :close do |event|
        logger.debug [:server, :close]
      end

      # Return async Rack response
      ws.rack_response
    end

    def log(message)
      logger.debug(message)
    end

    attr_reader :logger
    private :logger
  end

  require 'puma'
  require 'rack'
  require 'eventmachine'
  $em = Thread.new do
    begin
      EM.run do
        app = SocketApp.new(FakeResultsService.logger)
        events = Puma::Events.new(StringIO.new, StringIO.new)
        binder = Puma::Binder.new(events)
        binder.parse(["tcp://0.0.0.0:#{PORT}"], app)
        @server = Puma::Server.new(app, events)
        @server.binder = binder
        @server.run
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

if !respond_to?(:Before)
  # Standalone (manual test) mode
  $em.join
else
  # Cucumber mode
  Before { FakeResultsService.reset }
  After { FakeResultsService.logger.debug [:server, :messages, FakeResultsService.messages] }
  Before do
    write_file 'features/step_definitions/cucumber_pro.rb', <<-END
require 'cucumber/pro'
Cucumber::Pro.configure do |c|
  c.url = 'ws://localhost:#{FakeResultsService::PORT}'
end
    END
  end
end
