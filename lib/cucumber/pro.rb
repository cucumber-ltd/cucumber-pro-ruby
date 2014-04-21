module Cucumber
  module Pro
    def self.new(*args)
      Formatter.new(*args)
    end

    class Formatter
      def initialize(runtime, io, options)
        @session = Session.new('localhost', 54321)
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
    end

    require 'json'
    class Session
      def initialize(host, port)
        @ready = false
        start_client(host, port)
        loop until @ready
      end

      def send(message)
        p [:client, :send, message]
        @ws.send(message.to_json)
      end

      private

      def start_client(host, port)
        p [:client, :starting]
        Thread.new do
          EM.run do
            @ws = Faye::WebSocket::Client.new("ws://#{host}:#{port}")

            @ws.on(:open) do
              p [:client, :open]
              @ready = true
            end

            @ws.on(:message) do |event|
              p [:client, :message, event.data]
            end

            @ws.on(:close) do
              p [:client, :close]
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
