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

      class SendMessage
        def initialize(socket, data)
          @socket, @data = socket, data
        end

        def call
          @socket.send(@data.to_json)
        end
      end

      class Close
        def initialize(socket)
          @socket = socket
        end

        def call
          @socket.close
        end
      end

      def initialize(url, logger)
        @url, @logger = url, logger
        @queue = Queue.new
        @socket = SocketWriter.new(url, queue, logger, self)
      end

      def send(message)
        logger.debug [:session, :send, message]
        queue.push(SendMessage.new(socket, message))
      end

      def close
        logger.debug [:session, :close]
        socket.close
      end

      def error(exception)
        logger.fatal exception
        $stderr.puts "Cucumber Pro failed to send results: #{exception}"
        $stderr.puts exception.backtrace.join("\n")
      end

      private

      attr_reader :logger, :queue, :socket

      class SocketWriter

        def initialize(url, queue, logger, error_handler)
          @url, @queue, @logger, @error_handler = url, queue, logger, error_handler
          @em = Thread.new { start_client }
          @pending = 0
        end

        def close
          queue.push(Close.new(@ws))
          @em.join
        end

        def send(data)
          @ws.send data
        end

        private

        attr_reader :logger, :queue, :error_handler

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
          process_queue
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


        def process_queue
          queue.pop.call unless queue.empty?
          EM.next_tick do
            process_queue
          end
        end

      end

    end
  end
end
