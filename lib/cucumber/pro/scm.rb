module Cucumber
  module Pro

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

        def remote
          @repo.config['remote.origin.url']
        end

        def branch
          @repo.head.name
        end

        def rev
          @repo.head.commit.id
        end
      end
    end
  end
end
