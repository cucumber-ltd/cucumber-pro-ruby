module Cucumber
  module Pro

    module Error
      AccessDenied = Class.new(StandardError) {
        def initialize
          super "Access denied."
        end
      }

      Timeout = Class.new(StandardError) {
        def initialize
          super "Timed out waiting for a reply from the Cucumber Pro server."
        end
      }

      ServerError = Class.new(StandardError)
    end

  end
end
