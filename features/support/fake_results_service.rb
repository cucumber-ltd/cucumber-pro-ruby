require 'faye/websocket'
require 'json'

module FakeResultsService
  class << self
    attr_accessor :ready

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

  app = lambda do |env|
    ws = Faye::WebSocket.new(env)

    ws.on :open do |event|
      p [:server, :open]
      FakeResultsService.instance.ready = true
    end

    ws.on :message do |event|
      p [:server, :message, event.data]
      FakeResultsService.instance.messages << JSON.parse(event.data)
      ws.send 'ok'
    end

    ws.on :close do |event|
      p [:server, :close]
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
  Thread.new do
    EM.run do
      thin = Rack::Handler.get('thin')
      thin.run app, :Port => 54321
      trap("INT") { exit }
    end
  end

  loop until EM.reactor_running?
end

Before { FakeResultsService.instance.reset }
After { p [:server, :messages, FakeResultsService.instance.messages] }
