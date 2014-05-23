require 'cucumber/pro/web_socket/session'
require 'logger'

module Cucumber::Pro
  module WebSocket

    describe Worker do
      let(:good_data) { double('good data') }
      let(:error_handler) { double('error handler') }
      let(:logger) { Logger.new(STDOUT) }
      let(:socket) { FakeSocket.new }
      let(:worker) { Worker.new(self.method(:create_fake_socket), logger, error_handler, timeout: 1) }

      before { logger.level = Logger::DEBUG }

      it "closes once all messages have been acknowledged (but not before)" do
        worker.send(good_data)
        worker.close
        eventually do
          socket.data.last.should == good_data
        end
        eventually do
          expect( worker ).to_not be_closed
        end
        socket.send_ack
        eventually do
          expect( worker ).to be_closed
        end
      end

      it "throws an error and closes the socket if all messages are not acknowledged within a timeout period" do
        expect( error_handler ).to receive(:error).with(Error::Timeout.new)
        worker.send(good_data)
        worker.close
        eventually do
          expect( worker ).to be_closed
        end
      end

      it "throws an error if the server responds with an error"

      def create_fake_socket(worker)
        socket.worker = worker
        EM.next_tick {
          worker.method(:on_open).call(double('ws event'))
        }
        socket
      end


      class FakeSocket
        include RSpec::Mocks::ExampleMethods

        attr_accessor :worker
        attr_reader :data

        def initialize
          @data = []
        end

        def close
          worker.method(:on_close).call(ws_event(1000))
        end

        def send(data)
          @data << data
        end

        def send_ack
          event = ws_event(1000, { 'type' => 'metadata_saved' })
          worker.method(:on_message).call(event)
        end

        private

        def ws_event(code, data = {})
          double('ws event', code: 1000, data: data)
        end
      end

      require 'anticipate'
      include Anticipate
      def eventually(&block)
        result = nil
        sleeping(0.1).seconds.between_tries.failing_after(50).tries do
          result = block.call
        end
        result
      end
    end

  end
end
