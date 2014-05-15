module Cucumber
  module Pro

    module Scm

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
          @path = path
        end

        def remote
          cmd('git config --get remote.origin.url')
        end

        def branch
          cmd("git branch --contains #{rev}")
        end

        def rev
          cmd("git rev-parse HEAD")
        end

        private

        def cmd(cmd)
          Dir.chdir(@path) { `#{cmd}` }.strip
        end
      end
    end
  end
end
