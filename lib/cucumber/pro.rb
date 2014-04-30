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

      def before_feature(feature)
        @path = feature.file
      end

      def before_step_result(*args)
        keyword, step_match, multiline_arg, status, exception, source_indent, background, file_colon_line = *args
        path, line = *file_colon_line.split(':')
        @session.send({
          path: path,
          location: line.to_i,
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
          location: line.to_i,
          mime_type: 'application/vnd.cucumber.test-case-result+json',
          body: { status: scenario.status }
        })
      end

      def before_examples(*args)
        @header_row = true
        @in_examples = true
      end

      def after_examples(*args)
        @in_examples = false
      end

      def after_table_row(table_row)
        return unless @in_examples and Cucumber::Ast::OutlineTable::ExampleRow === table_row
        unless @header_row
          @session.send({
            path: @path,
            location: table_row.line,
            mime_type: 'application/vnd.cucumber.test-case-result+json',
            body: { status: table_row.status }
          })
        end
        @header_row = false if @header_row
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
