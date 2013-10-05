module Cucumber
  module Pro
    def self.new(*args)
      Formatter.new(*args)
    end

    class Formatter
      def initialize(runtime, io, options)
      end

      def before_step_result(*args)
        raise "Not ready to deal with new API" if args.length == 1
        keyword, step_match, multiline_arg, status, exception, source_indent, background, file_colon_line = *args
        p [file_colon_line, status]
      end
    end
  end
end
