module Cucumber
  module Pro

    module Scm

      class WorkingCopy

        NoGitRepoFound = Class.new(StandardError)

        def self.detect(path = Dir.pwd)
          if Dir.entries(path).include? '.git'
            GitWorkingCopy.new(path)
          else
            raise NoGitRepoFound if path == '/'
            find File.expand_path(path + '/..')
          end
        end

      end

      class GitWorkingCopy

        def initialize(path)
          @path = path
        end

        def repo_url
          cmd('git config --get remote.origin.url').last
        end

        def branch
          branch = cmd("git branch --contains #{rev}").
            reject { |b| /^\* \(detached from \w+\)/.match b }.
            first.
            gsub(/^\* /, '')
        end

        def rev
          cmd("git rev-parse HEAD").last
        end

        private

        def cmd(cmd)
          Dir.chdir(@path) { `#{cmd}` }.lines.map &:strip
        end
      end
    end
  end
end
