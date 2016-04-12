require 'spec_helper'

require 'green_eye_monitor/client'

describe GreenEyeMonitor::Client do
  describe 'API' do
    let(:serial_port) { double('Serial Port') }
    let(:client) { described_class.new }

    before do
      expect(SerialPort).to receive(:new).with('/dev/ttyUSB0', :baud => 115_200).and_return(serial_port)

      expect(serial_port).to receive(:flush_output)
      expect(serial_port).to receive(:flush_input)
      expect(serial_port).to receive(:read_timeout=)
    end

    it 'resets' do
      expect(serial_port).to receive(:syswrite).with('^^^SYSOFF')
      expect(serial_port).to receive(:syswrite).with('^^^SYSOFF')
      expect(serial_port).to receive(:syswrite).with('^^^SYSOFF')

      data = [nil, nil, nil, 'O', 'F', 'F', nil]
      data.each do |byte|
        expect(serial_port).to receive(:getbyte).and_return(byte)
      end

      client.reset
    end
  end
end
