require 'faye/websocket'

module FakeResultsService
  app = lambda do |env|
    ws = Faye::WebSocket.new(env)

    ws.on :message do |event|
      FakeResultsService.instance.messages << event
      ws.send(event.data)
    end

    ws.on :close do |event|
      EM.stop_event_loop
      ws = nil
    end

    # Return async Rack response
    ws.rack_response
  end

  require 'thin'
  require 'rack'
  require 'eventmachine'
  Faye::WebSocket.load_adapter('thin')
  em = Thread.new do
    EM.run do
      thin = Rack::Handler.get('thin')
      thin.run(app, :Port => 54321)
    end
  end

  loop until EM.reactor_running?

  at_exit do
    EM.stop
    em.join
  end

  class << self
    def messages
      @messages ||= []
    end

    def reset
      @messages = nil
    end

    def instance
      self
    end
  end
end

Before { FakeResultsService.instance.reset }
