require 'json'
require 'faye/websocket'
require 'eventmachine'

module Cucumber
  module Pro

    class WebSocketSession

      class SendMessage
        def initialize(data)
          @data = data
        end

        def send_to(ws)
          ws.send(@data.to_json)
        end
      end

      class Close
        def send_to(ws)
          ws.close
        end
      end

      def initialize(host, port, logger)
        @url = "ws://#{host}:#{port}"
        @logger = logger
        @queue = Queue.new
        start
      end

      def send(message)
        logger.debug [:session, :send, message]
        queue.push(SendMessage.new(message))
      end

      def close
        logger.debug [:session, :close]
        queue.push(Close.new)
        @em.join
      end

      private

      attr_reader :logger, :queue

      def start
        @em = Thread.new do
          begin
            EM.run { start_ws_client }
          rescue => exception
            logger.fatal exception
            puts exception, exception.backtrace.join("/n")
            exit 1
          end
        end
      end

      def start_ws_client
        logger.debug [:ws, :start]
        ws = Faye::WebSocket::Client.new(@url)

        ws.on(:open) do
          logger.debug [:ws, :open]
          process_queue(ws)
        end

        ws.on(:error) do
          logger.error [:ws, :error]
        end

        ws.on(:message) do |event|
          logger.debug [:ws, :message, event.data]
        end

        ws.on(:close) do
          logger.debug [:ws, :close]
          ws = nil
          EM.stop_event_loop
        end
        self
      end

      def process_queue(ws)
        process_next_message(ws)
        EM.next_tick do
          process_queue(ws)
        end
      end

      def process_next_message(ws)
        return if queue.empty?
        message = queue.pop
        message.send_to(ws)
        logger.debug [:ws, :send, message]
      end

    end
  end
end