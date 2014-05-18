require 'cucumber/pro/web_socket/session'
require 'logger'

module Cucumber::Pro::WebSocket

  describe Worker do
    let(:logger) { Logger.new(STDOUT) }
    before { logger.level = Logger::INFO }

    it "closes once all messages have been acknowledged" do
      socket = double('Socket')
      error_handler = self
      create_socket = -> worker { 
        socket.stub(:close) do
          worker.method(:on_close).call(double('ws event', code: 1000))
        end
        socket
      }
      worker = Worker.new(create_socket, logger, logger) do
        p :work
      end
      worker.close
      loop until worker.closed?
    end
  end
end
