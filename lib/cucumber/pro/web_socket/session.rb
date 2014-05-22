require 'json'
require 'faye/websocket'
require 'eventmachine'

module Cucumber
  module Pro
    module WebSocket

      class Session

        def initialize(url, logger)
          @url, @logger = url, logger
          create_socket = -> worker {
            ws = Faye::WebSocket::Client.new(@url, nil, ping: 15)
            ws.on :open,    &worker.method(:on_open)
            ws.on :error,   &worker.method(:on_error)
            ws.on :message, &worker.method(:on_message)
            ws.on :close,   &worker.method(:on_close)
            ws
          }
          @queue = Queue.new
          @socket = Worker.new(create_socket, logger, self)
        end

        def send(message)
          logger.debug [:session, :send, message]
          socket.send(message.to_json)
          self
        end

        def close
          logger.debug [:session, :close]
          socket.close
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
      end

      class Worker

        def initialize(create_socket, logger, error_handler)
          @create_socket, @logger, @error_handler = create_socket, logger, error_handler
          @q = Queue.new
          @em = Thread.new { start_client }
          @ack_count = 0
        end

        def close
          @q << -> {
            if @ack_count == 0
              @ws.close
            else
              EM.next_tick { close }
            end
          }
          self
        end

        def send(data)
          @q << -> {
            @ws.send data
            @ack_count += 1
          }
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
          @q.pop.call if !@q.empty?
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
