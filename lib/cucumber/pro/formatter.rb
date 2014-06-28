require 'cucumber/pro/scm/working_copy'
require 'cucumber/pro/info'
require 'securerandom'

module Cucumber
  module Pro

    class Formatter
      def initialize(session, working_copy)
        @session = session
        @working_copy = working_copy
        send_header
      end

      def before_feature(feature)
        @path = feature.file # we need this because table_row doens't have a file_colon_line
      end

      def before_step_result(*args)
        keyword, step_match, multiline_arg, status, exception, source_indent, background, file_colon_line = *args
        path, line = *file_colon_line.split(':')
        send_step_result(path, line, status)
      end

      def after_feature_element(feature_element)
        return if Cucumber::Ast::ScenarioOutline === feature_element
        scenario = feature_element
        path, line = *scenario.file_colon_line.split(':')
        send_test_case_result(path, line, scenario.status)
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
        if @header_row
          @header_row = false
          return
        end
        send_test_case_result(@path, table_row.line, table_row.status)
      end

      def after_features(*args)
        @session.close
      end

      private

      def send_header
        @session.send_message({
          repo_url: @working_copy.repo_url,
          branch: @working_copy.branch,
          rev: @working_copy.rev,
          group: get_run_id,
          info: Info.new.to_h
        })
      end

      def send_step_result(path, line, status)
        @session.send_message({
          path: path,
          location: line.to_i,
          mime_type: 'application/vnd.cucumber.test-step-result+json',
          body: { status: status }
        })
      end

      def send_test_case_result(path, line, status)
        @session.send_message({
          path: path,
          location: line.to_i,
          mime_type: 'application/vnd.cucumber-pro.test-case-result+json',
          body: { status: status }
        })
      end

      def get_run_id
        SecureRandom.hex
      end

    end

  end
end
