require 'cucumber/pro/info'

module Cucumber
  module Pro
    describe Info do
      it "can create a meaningful Hash" do
        info = Info.new
        expect(info.to_h[:client_version]).to match(/^cucumber-pro-ruby/)
        expect(info.to_h[:cmd]).to match(/rspec/)
      end
    end
  end
end
