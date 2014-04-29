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
        @session.send({
          repo_url: 'git@github.com/cucumber/cucumber',
          branch: 'master',
          rev: 'abcdef0123',
          group: 'made-up-id'
        })
      end

      def before_step_result(*args)
        keyword, step_match, multiline_arg, status, exception, source_indent, background, file_colon_line = *args
        @session.send({
          path: 'features/foo.feature',
          location: 2,
          mime_type: 'application/vnd.cucumber.test-step-result+json',
          body: { status: status }
        })
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
