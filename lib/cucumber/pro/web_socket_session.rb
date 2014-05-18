require 'json'
require 'faye/websocket'
require 'eventmachine'

module Cucumber
  module Pro
    class WebSocketSession

      def initialize(url, logger)
        @url, @logger = url, logger
        create_socket = -> worker {
          ws = Faye::WebSocket::Client.new(@url)
          ws.on :open,    &worker.method(:on_open)
          ws.on :error,   &worker.method(:on_error)
          ws.on :message, &worker.method(:on_message)
          ws.on :close,   &worker.method(:on_close)
          ws
        }
        @queue = Queue.new
        @socket = SocketWorker.new(create_socket, logger, self) do
          queue.pop.call if !queue.empty?
        end
      end

      def send(message)
        logger.debug [:session, :send, message]
        queue.push -> { socket.send(message.to_json) }
        self
      end

      def close
        logger.debug [:session, :close]
        queue.push -> { socket.close }
        loop until socket.closed?
        self
      end

      def error(exception)
        logger.fatal exception
        $stderr.puts "Cucumber Pro failed to send results: #{exception}"
        $stderr.puts exception.backtrace.join("\n")
        self
      end

      private

      attr_reader :logger, :queue, :socket

      class SocketWorker

        def initialize(create_socket, logger, error_handler, &next_task)
          @create_socket, @logger, @error_handler = create_socket, logger, error_handler
          @next_task = next_task
          @em = Thread.new { start_client }
          @ack_count = 0
        end

        def close
          loop until @ws
          if @ack_count == 0
            @ws.close
          else
            EM.next_tick { close }
          end
          self
        end

        def send(data)
          @ws.send data
          @ack_count += 1
          self
        end

        def closed?
          !@em.alive?
        end

        private

        attr_reader :logger, :error_handler, :next_task

        def start_client
          EM.run do
            logger.debug [:ws, :start]
            @ws = @create_socket.call(self)
          end
          self
        rescue => exception
          error_handler.error exception
        end

        def on_open(event)
          logger.debug [:ws, :open]
          process_tasks
          self
        end

        def on_error(event)
          logger.error [:ws, :error]
          self
        end

        def on_message(event)
          logger.debug [:ws, :message, event.data]
          @ack_count -= 1
          self
        end

        def on_close(event)
          logger.debug [:ws, :close]
          if access_denied?(event)
            raise Error::AccessDenied.new 
          end
          @ws = nil
          EM.stop_event_loop
          self
        end

        def process_tasks
          next_task.call
          EM.next_tick { process_tasks }
          self
        end

        def access_denied?(event)
          event.code == 1002 && 
            event.reason == \
            "Error during WebSocket handshake: Unexpected response code: 401"
        end

      end

    end
  end
end
