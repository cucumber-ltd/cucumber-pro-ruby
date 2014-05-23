module Cucumber
  module Pro

    module Error
      AccessDenied = Class.new(StandardError) {
        def initialize
          super "Access denied."
        end
      }

      MissingToken = Class.new(StandardError) {
        def initialize
          super "Missing access token. Please visit https://app.cucumber.pro/api-token for instructions."
        end
      }

      Timeout = Class.new(StandardError) {
        def initialize
          super "Timed out waiting for a reply from the Cucumber Pro server."
        end
      }
    end

  end
end
