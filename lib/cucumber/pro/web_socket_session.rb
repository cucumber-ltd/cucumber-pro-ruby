require 'json'
require 'faye/websocket'
require 'eventmachine'

module Cucumber
  module Pro
    module Error
      AccessDenied = Class.new(StandardError) {
        def initialize
          super "Access denied."
        end
      }
    end

    class WebSocketSession

      def initialize(url, logger)
        @url, @logger = url, logger
        @queue = Queue.new
        @socket = SocketWriter.new(url, logger, self) do
          queue.pop.call if !queue.empty?
        end
      end

      def send(message)
        logger.debug [:session, :send, message]
        queue.push -> { socket.send(message.to_json) }
      end

      def close
        logger.debug [:session, :close]
        queue.push -> { socket.close }
        loop until socket.closed?
      end

      def error(exception)
        logger.fatal exception
        $stderr.puts "Cucumber Pro failed to send results: #{exception}"
        $stderr.puts exception.backtrace.join("\n")
      end

      private

      attr_reader :logger, :queue, :socket

      class SocketWriter

        def initialize(url, logger, error_handler, &next_task)
          @url, @logger, @error_handler = url, logger, error_handler
          @next_task = next_task
          @em = Thread.new { start_client }
        end

        def close
          @ws.close
        end

        def send(data)
          @ws.send data
        end

        def closed?
          !@em.alive?
        end

        private

        attr_reader :logger, :error_handler, :next_task

        def start_client
          EM.run do
            logger.debug [:ws, :start]
            @ws = Faye::WebSocket::Client.new(@url)
            @ws.on :open,    &self.method(:on_open)
            @ws.on :error,   &self.method(:on_error)
            @ws.on :message, &self.method(:on_message)
            @ws.on :close,   &self.method(:on_close)
          end
          self
        rescue => exception
          error_handler.error exception
        end

        def on_open(event)
          logger.debug [:ws, :open]
          process_tasks
        end

        def on_error(event)
          logger.error [:ws, :error]
        end

        def on_message(event)
          logger.debug [:ws, :message, event.data]
        end

        def on_close(event)
          logger.debug [:ws, :close]
          raise Error::AccessDenied.new if event.code == 401
          @ws = nil
          EM.stop_event_loop
        end

        def process_tasks
          next_task.call
          EM.next_tick { process_tasks }
        end

      end

    end
  end
end
