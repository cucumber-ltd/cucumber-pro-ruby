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
        scm = Scm::Repo.find
        @session = WebSocketSession.new('localhost', 5000, logger)
        @session.send({
          repo_url: scm.remote,
          branch: scm.branch,
          rev: scm.rev,
          group: get_run_id
        })
      end

      def before_step_result(*args)
        keyword, step_match, multiline_arg, status, exception, source_indent, background, file_colon_line = *args
        path, line = *file_colon_line.split(':')
        @session.send({
          path: path,
          location: line,
          mime_type: 'application/vnd.cucumber.test-step-result+json',
          body: { status: status }
        })
      end

      def after_feature_element(feature_element)
        return if Cucumber::Ast::ScenarioOutline === feature_element
        scenario = feature_element
        path, line = *scenario.file_colon_line.split(':')
        @session.send({
          path: path,
          location: line,
          mime_type: 'application/vnd.cucumber.test-case-result+json',
          body: { status: scenario.status }
        })
      end

      def after_features(*args)
        @session.close
      end

      private

      def get_run_id
        Time.now.to_i
      end
    end

  end
end
