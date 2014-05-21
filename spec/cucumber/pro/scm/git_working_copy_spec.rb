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
            run_simple "git config user.email \"test@test.com\""
            run_simple "git config user.name \"Test user\""
          end
        end

        it "figures out the name of the branch, even on CI" do
          in_current_dir do
            run_simple "git commit --allow-empty -m 'Initial commit'"
            run_simple "git rev-parse HEAD"
            rev = all_stdout.split("\n").last
            run_simple "git checkout #{rev}"
            working_copy = WorkingCopy.detect(current_dir)
            expect( working_copy.branch ).to eq "master"
          end
        end

        it "figures out the name of the branch when that's what's checked out" do
          in_current_dir do
            run_simple "git commit --allow-empty -m 'Initial commit'"
            working_copy = WorkingCopy.detect(current_dir)
            expect( working_copy.branch ).to eq "master"
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

        xit "detects unpushed changes" do
          # This one is a little trickier to test. I think we may have to fetch commits
          # from a repo first.
          in_current_dir do
            write_file "README.md", "# README"
            run_simple "git add README.md"
            run_simple "git commit -am 'I committed but that is not good enough'"
            working_copy = WorkingCopy.detect(current_dir)
            expect { working_copy.check_clean }.to raise_error(DirtyWorkingCopy, /Your current branch has commits that haven't been pushed to origin/)
          end
        end
      end
    end
  end
end
