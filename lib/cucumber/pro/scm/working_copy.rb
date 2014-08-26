module Cucumber
  module Pro

    module Scm

      DirtyWorkingCopy = Class.new(StandardError)

      class WorkingCopy

        NoGitRepoFound = Class.new(StandardError)

        def self.detect(path = Dir.pwd)
          if Dir.entries(path).include? '.git'
            GitWorkingCopy.new(path)
          else
            # TODO (aslak): This is likely to loop indefinitely on Windows - it's never '/'
            # Maybe use Pathname?
            raise NoGitRepoFound if path == '/'
            detect File.expand_path(path + '/..')
          end
        end

      end

      class GitWorkingCopy

        def initialize(path)
          @path = path
        end

        def repo_url
          cmd('git ls-remote --get-url').each do |remote|
            return remote if remote =~ /(github|bitbucket)/
          end
          # Fallback if we didn't find one
          cmd('git config --get remote.origin.url').last
        end

        # tries to return the name of the origin branch that points to the current HEAD
        def branch
          if remote_refs.empty?
            # just use local branch name
            return cmd("git name-rev --name-only HEAD")[0]
          end
          if remote_refs.length > 1
            fail "Multiple remote branches point to this commit: #{remote_refs.join(',')}"
          end
          remote_refs.first.gsub(/refs\/remotes\/\w+\//, '')
        end

        def rev
          cmd("git rev-parse HEAD").last
        end

        def check_clean
          check_no_modifications
          check_current_branch_pushed
        end

        private

        def remote_refs
          @remote_refs ||= refs.
            select { |ref| ref =~ /refs\/remotes/ }.
            reject { |ref| ref =~ /refs\/remotes\/\w+\/HEAD/ }
        end

        def refs
          @refs ||= cmd("git show-ref | grep #{rev}").map { |output| output.split[1] }
        end

        def cmd(cmd)
          Dir.chdir(@path) { `#{cmd}` }.lines.map &:strip
        end

        def check_no_modifications
          if cmd("git status --untracked-files=no --porcelain").any?
            raise DirtyWorkingCopy.new("Please commit and push your changes before running with the Cucumber Pro formatter.")
          end
        end

        def check_current_branch_pushed
          if cmd("git branch -r").any?
            # Only check if it's pushed if we actually have any remote branches
            # (which we do not for our tests)
            b = branch
            if cmd("git log origin/#{b}..#{b} --oneline").any?
              raise DirtyWorkingCopy.new("Your current branch has commits that haven't been pushed to origin. Please push your changes before running with the Cucumber Pro formatter.")
            end
          end
        end
      end
    end
  end
end
