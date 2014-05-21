require 'cucumber/pro/scm/working_copy'
require 'aruba/api'

module Cucumber
  module Pro
    module Scm
      describe GitWorkingCopy do
        include Aruba::Api
        before do
          clean_current_dir
        end

        it "figures out the name of the branch, even on CI" do
          in_current_dir do
            run_simple "git init"
            run_simple "git config user.email \"test@test.com\""
            run_simple "git config user.name \"Test user\""
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
            run_simple "git init"
            run_simple "git config user.email \"test@test.com\""
            run_simple "git config user.name \"Test user\""
            run_simple "git commit --allow-empty -m 'Initial commit'"
            working_copy = WorkingCopy.detect(current_dir)
            expect( working_copy.branch ).to eq "master"
          end
        end
      end
    end
  end
end
