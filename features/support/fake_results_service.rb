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

  logger = self.logger

  SocketApp = lambda do |env|
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
    end

    # Return async Rack response
    ws.rack_response
  end

  class Security
    def initialize(app)
      @app = app
    end

    def call(env)
      request = Rack::Request.new(env)
      params = request.params
      return [401, [], {}] unless params['token'] == VALID_TOKEN
      @app.call(env)
    end
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
        app = Security.new(SocketApp)
        thin.run app, :Port => PORT
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
