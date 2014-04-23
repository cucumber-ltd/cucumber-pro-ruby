require 'logger'

module Cucumber
  module Pro
    def self.new(*args)
      Formatter.new(*args)
    end

    class Formatter
      def initialize(runtime, io, options)
        @logger = Logger.new(ENV['cucumber_pro_log_path'] || STDOUT)
        @session = Session.new('localhost', 54321, @logger)
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
    class Session
      def initialize(host, port, logger)
        @logger = logger
        @ready = false
        start_client(host, port)
        start_transmitter
        loop until @ready || @error
      end

      def send(message)
        logger.debug [:session, :send, message]
        @queue.push(message)
      end

      def close
        @queue.push :stop
        @transmitter_thread.join
      end

      private

      attr_reader :logger

      def start_transmitter
        @queue = Queue.new
        @transmitter_thread = Thread.new do
          loop do
            message = @queue.pop
            logger.debug [:transmit, message]
            break if message == :stop
            logger.debug [:socket, :send, message]
            @ws.send(message.to_json)
          end
          # hack to ensure that the socket gets a chance to send the last message before we close it
          sleep 1
        end
      end

      require 'faye/websocket'
      require 'eventmachine'
      def start_client(host, port)
        logger.debug [:client, :starting]
        em = Thread.new do
          EM.run do
            @ws = Faye::WebSocket::Client.new("ws://#{host}:#{port}")

            @ws.on(:open) do
              logger.debug [:client, :open]
              @ready = true
            end

            @ws.on(:error) do
              logger.debug [:client, :error]
              @error = true
            end

            @ws.on(:message) do |event|
              logger.debug [:client, :message, event.data]
            end

            @ws.on(:close) do
              logger.debug [:client, :close]
              ws = nil
            end
          end
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
