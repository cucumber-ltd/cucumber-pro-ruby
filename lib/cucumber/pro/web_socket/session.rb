require 'json'
require 'faye/websocket'
require 'eventmachine'
require 'cucumber/pro/errors'

module Cucumber
  module Pro
    module WebSocket
      class NullSession
        def send_message(message)
        end

        def close
        end
      end

      class Session

        def initialize(url, logger, options)
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
          @socket = Worker.new(create_socket, logger, self, options)
        end

        def send_message(message)
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

        def initialize(create_socket, logger, error_handler, options = {})
          @create_socket, @logger, @error_handler = create_socket, logger, error_handler
          @timeout = options.fetch(:timeout) { raise ArgumentError("Please specify timeout") }
          @q = Queue.new
          @em = Thread.new { start_client }
          @ack_count = 0
        end

        def close
          @q << -> {
            if @ack_count == 0
              close_websocket
            else
              ensure_close_timer_started
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

        attr_reader :logger, :error_handler, :next_task, :timeout

        def ensure_close_timer_started
          return if @close_timer
          logger.debug [:ws, :set_close_timeout, timeout]
          @close_timer = EM.add_timer(timeout) { handle_close_timeout }
        end

        def handle_close_timeout
          logger.debug [:ws, :handle_close_timeout]
          return unless @ws
          error_handler.error Error::Timeout.new
          close_websocket
        end

        def close_websocket
          logger.debug [:ws, :close_socket]
          @ws.close
        end

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
          message = JSON.parse(event.data)
          if(message['error'])
            raise Error::ServerError.new(message['error'])
          end
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
