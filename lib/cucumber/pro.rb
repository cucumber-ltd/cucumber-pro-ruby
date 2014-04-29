require 'logger'
require 'cucumber/pro/web_socket_session'
require 'cucumber/pro/scm'

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


  end
end
