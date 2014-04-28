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
      module State
        Starting = :starting
        Started = :started
        Stopping = :stopping
        Stopped = :stopped
      end

      def initialize(host, port, logger)
        @url = "ws://#{host}:#{port}"
        @logger = logger
        @queue = Queue.new
        start
      end

      def send(message)
        logger.debug [:session, :send, message]
        queue.push(message)
      end

      def close
        logger.debug [:session, :close]
        enter_state State::Stopping
        until stopped?
          logger.debug [:stopping, :state, @state]
          sleep 0.1
        end
        EM.stop_event_loop
        @em.join
      end

      private

      attr_reader :logger, :queue

      def start
        enter_state State::Starting
        @em = Thread.new do
          begin
            EM.run do
              open_socket do |ws|
                enter_state State::Started
                send_next_message(ws)
              end
            end
          rescue => exception
            logger.fatal exception
            puts exception, exception.backtrace.join("/n")
            exit 1
          end
        end

        loop until started?
      end

      def open_socket(&block)
        logger.debug [:ws, :start]
        ws = Faye::WebSocket::Client.new(@url)

        ws.on(:open) do
          logger.debug [:ws, :open]
          block.call(ws)
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
        end
      end

      def send_next_message(ws)
        if ready_to_stop?
          enter_state State::Stopped
          return
        end
        if !queue.empty?
          message = queue.pop
          logger.debug [:ws, :send, message]
          ws.send(message.to_json)
        end
        EM.next_tick do
          send_next_message(ws)
        end
      end

      def enter_state(new_state)
        return if @state == new_state
        @state = new_state
        logger.debug [:enter_state, new_state]
        self
      end

      def started?
        @state == State::Started
      end

      def ready_to_stop?
        logger.debug [:ready_to_stop?, queue.empty?, @state]
        return unless queue.empty?
        @state == State::Stopping || @state == State::Stopped
      end

      def stopped?
        @state == State::Stopped
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
