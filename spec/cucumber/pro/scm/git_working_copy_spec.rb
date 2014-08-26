require 'cucumber/pro/scm/working_copy'
require 'aruba/api'

module Cucumber
  module Pro
    module Scm
      describe GitWorkingCopy do
        include Aruba::Api
        before do
          clean_current_dir
          in_current_dir do
            run_simple "git init"
            git_config
          end
        end

        it "figures out the name of the branch, even on CI" do
          create_origin_repo
          clone_origin_repo
          commit_and_push
          # check out the remote branch
          run_simple "git checkout remotes/origin/master"
          # delete master branch
          run_simple "git branch -D master"
          working_copy = WorkingCopy.detect(current_dir)
          expect( working_copy.branch ).to eq "master"
        end

        it "figures out the name of the branch, even when the local branch has a different name" do
          create_origin_repo
          clone_origin_repo
          commit_and_push
          # check out the remote branch with a different name
          run_simple "git checkout -b foo --track origin/master"
          working_copy = WorkingCopy.detect(current_dir)
          expect( working_copy.branch ).to eq "master"
        end

        it "figures out the name of the branch when that's what's checked out" do
          in_current_dir do
            run_simple "git commit --allow-empty -m 'Initial commit'"
            working_copy = WorkingCopy.detect(current_dir)
            expect( working_copy.branch ).to eq "master"
          end
        end

        it "figures out the name of the branch when it has a name that looks like a remote branch" do
          in_current_dir do
            run_simple "git commit --allow-empty -m 'Initial commit'"
            run_simple "git checkout -b remotes/foo/bar"
            run_simple "git commit --allow-empty -m 'Another commit'"
            working_copy = WorkingCopy.detect(current_dir)
            expect( working_copy.branch ).to eq "remotes/foo/bar"
          end
        end

        it "detects a dirty working copy" do
          in_current_dir do
            write_file "README.md", "# README"
            run_simple "git add README.md"
            working_copy = WorkingCopy.detect(current_dir)
            expect { working_copy.check_clean }.to raise_error(DirtyWorkingCopy, /Please commit and push your changes/)
          end
        end

        it "detects unpushed changes to an existing file" do
          create_origin_repo
          clone_origin_repo
          commit_and_push "foo"
          write_file "foo", "contents"
          run_simple "git add ."
          run_simple "git commit -m 'foo'"
          working_copy = WorkingCopy.detect(current_dir)
          expect { working_copy.check_clean }.to raise_error(DirtyWorkingCopy, /Your current branch has commits that haven't been pushed to origin/)
        end

        it "detects unpushed changes to a new file" do
          create_origin_repo
          clone_origin_repo
          commit_and_push "foo"
          run_simple "touch bar"
          run_simple "git add ."
          run_simple "git commit -m 'bar'"
          working_copy = WorkingCopy.detect(current_dir)
          expect { working_copy.check_clean }.to raise_error(DirtyWorkingCopy, /Your current branch has commits that haven't been pushed to origin/)
        end

        it "detects a dirty working directory" do
          create_origin_repo
          clone_origin_repo
          commit_and_push "foo"
          write_file "foo", "contents"
          working_copy = WorkingCopy.detect(current_dir)
          expect { working_copy.check_clean }.to raise_error(DirtyWorkingCopy, /Please commit and push your changes before running with the Cucumber Pro formatter/)
        end

        def create_origin_repo
          create_dir "origin"
          cd "origin"
          run_simple "git init --bare"
          git_config
          cd ".."
        end

        def clone_origin_repo
          run_simple "git clone ./origin local"
          cd "local"
        end

        def commit_and_push(filename = 'foo')
          run_simple "touch #{filename}"
          run_simple "git add ."
          run_simple "git commit -m '#{commit_message}'"
          run_simple "git push"
        end

        def commit_message
          @commit_number ||= 0
          "Commit message #{@commit_number += 1}"
        end

        def git_config
          run_simple "git config user.email \"test@test.com\""
          run_simple "git config user.name \"Test user\""
        end

      end
    end
  end
end
