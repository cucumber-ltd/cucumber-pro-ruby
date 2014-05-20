require 'cucumber/pro/info'

module Cucumber
  module Pro
    describe Info do
      it "can create a meaningful Hash" do
        expect(Info.new.to_h[:client_version]).to match(/^cucumber-pro-ruby/)
      end
    end
  end
end
