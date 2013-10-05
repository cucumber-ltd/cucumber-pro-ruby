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
        p [file_colon_line, status, Scm::Repo.find.slug]
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
