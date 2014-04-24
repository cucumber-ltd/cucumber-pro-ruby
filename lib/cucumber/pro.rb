require 'logger'

module Cucumber
  module Pro
    def self.new(*args)
      Formatter.new(*args)
    end

    class Formatter
      def initialize(runtime, io, options)
        logger = Logger.new(ENV['cucumber_pro_log_path'] || STDOUT)
        @session = WebSocketSession.new('localhost', 5001, logger)
      end

      def before_step_result(*args)
        keyword, step_match, multiline_arg, status, exception, source_indent, background, file_colon_line = *args
        @session.send(body: { status: status })
        # p [:step, file_colon_line, status, Scm::Repo.find.slug]
      end

      def after_feature_element(feature_element)
        return if Cucumber::Ast::ScenarioOutline === feature_element
        scenario = feature_element
        # p [:scenario, scenario.file_colon_line, scenario.status, Scm::Repo.find.slug]
      end

      def after_features(*args)
        @session.close
      end
    end

    require 'json'
    require 'faye/websocket'
    require 'eventmachine'
    class WebSocketSession
      def initialize(host, port, logger)
        @url = "ws://#{host}:#{port}"
        @logger = logger
        @queue = Queue.new
        start(queue)
      end

      def send(message)
        logger.debug [:session, :send, message]
        queue.push(message)
      end

      def close
        logger.debug [:session, :close]
        @please_stop = true
        loop until @stopped
        EM.stop_event_loop
        @em.join
      end

      private

      attr_reader :logger, :queue

      def start(queue)
        open = false
        @em = Thread.new do
          logger.debug [:ws, :start]
          begin
            EM.run do
              ws = Faye::WebSocket::Client.new(@url)

              ws.on(:open) do
                logger.debug [:ws, :open]
                until @please_stop && queue.empty? do
                  open = true
                  message = queue.pop
                  logger.debug [:ws, :send, message]
                  ws.send(message.to_json)
                end
                @stopped = true
              end

              ws.on(:error) do
                logger.debug [:ws, :error]
                @error = true
              end

              ws.on(:message) do |event|
                logger.debug [:ws, :message, event.data]
              end

              ws.on(:close) do
                logger.debug [:ws, :close]
                ws = nil
              end
            end
          rescue => exception
            logger.fatal exception
            puts exception, exception.backtrace.join("/n")
            exit 1
          end
          loop until open
        end

      end
    end

    module Scm

      require 'grit'
      class Repo

        NoGitRepoFound = Class.new(StandardError)

        def self.find(path = Dir.pwd)
          if Dir.entries(path).include? '.git'
            new(path)
          else
            raise NoGitRepoFound if path == '/'
            find File.expand_path(path + '/..')
          end
        end

        def initialize(path)
          @repo = Grit::Repo.new(path)
        end

        def slug
          remote.match(/:(.+)\/(.+).git/).captures.join('/')
        end

        private

        def remote
          @repo.config['remote.origin.url']
        end
      end
    end
  end
end
