require 'green_eye_monitor/errors'

require 'serialport'

module GreenEyeMonitor
  class Client
    PACKET_FORMATS = {
      :list           => 0,
      :multi          => 1,
      :ascii          => 2,
      :http           => 3,
      :bin48_net_time => 4,
      :bin43_net      => 5,
      :old_seg        => 6,
      :bin48_abs      => 7,
      :bin32_net      => 8,
      :bin32_abs      => 9,
      # 10
      :universal      => 11,
      # 12
      :cosm           => 12,
      :seg            => 13,
    }

    BAUD_RATES = {
      19_200  => 0,
      115_200 => 1,
    }

    def initialize(options = {})
      serial_port = options[:serial_port] || '/dev/ttyUSB0'
      baud = options[:baud] || 115_200
      @debug = options[:debug] || false

      @serial = SerialPort.new(serial_port, 'baud' => baud)

      @serial.flush_output
      @serial.flush_input
      @serial.read_timeout = 100
    end

    def shell
      old_command = ''

      loop do
        print 'Command: '
        command = STDIN.readline
        command.strip!
        command = old_command if command.empty?
        @serial.syswrite("^^^#{command}")
        puts read
        old_command = command
      end
    end

    def reset
      @serial.syswrite('^^^RQSSRN')
      @serial.syswrite('^^^RQSSRN')
      @serial.syswrite('^^^RQSSRN')
      read
      read
      read
      read
    end

    def disable_realtime
      @serial.syswrite('^^^SYSOFF')
      read('OFF')
    end

    def enable_realtime
      @serial.syswrite('^^^SYS_ON')
      read('_ON')
    end

    def disable_keepalive
      @serial.syswrite('^^^SYSKAI0')
      read('OK')
    end

    def enable_keepalive(seconds)
      # 2**x == seconds we aproximate to closest

      x = Math.log2(seconds).round
      x = 7 if x > 7
      x = 1 if x == 0

      @serial.syswrite("^^^SYSKAI#{x}")
      read('OK')
    end

    # rubocop:disable Style/AccessorMethodName
    def set_packet_format(packet_format)
      int_format = PACKET_FORMATS[packet_format] || fail(Errors::Argument, 'Unknown packet format')

      @serial.syswrite(format('^^^SYSPKT%02d', int_format))
      read('PKT')
    end

    def set_secondary_packet_format(packet_format)
      int_format = PACKET_FORMATS[packet_format] || fail(Errors::Argument, 'Unknown packet format')

      @serial.syswrite(format('^^^SYSPKF%02d', int_format))
      read('PKT')
    end

    def disable_secondary_packet_format
      @serial.syswrite('^^^SYSPKF00')
      read('PKT')
    end

    def set_packet_send_interval(seconds)
      fail(Errors::Argument, 'Invalid interval: must be between 1 and 256') unless seconds > 0 && seconds <= 256

      @serial.syswrite(format('^^^SYSIVL%03d', seconds))
      read('IVL')
    end

    def set_packet_chunk_size(size)
      fail(Errors::Argument, 'Invalid chunk size: must be between 80 and 65,000') unless size >= 80 && size <= 65_000

      @serial.syswrite("^^^SYSPKS#{size}\n")
      read('PKS')
    end

    def set_packet_chunk_interval(seconds)
      fail(Errors::Argument, 'Invalid interval: must be between 16 and 65,000') unless seconds >= 16 && seconds <= 65_000

      @serial.syswrite("^^^SYSPKI#{seconds}\n")
      read('PKI')
    end

    def set_max_buffer_size(size)
      fail(Errors::Argument, 'Invalid buffer size: must be between 10 and 1,700') unless size >= 10 && size <= 1_700

      @serial.syswrite("^^^SYSBFF#{size}\n")
      read('BFF')
    end

    def set_com1_baud_rate(rate)
      int_rate = BAUD_RATES[rate] || fail(Errors::Argument, 'Unknown baud rate')

      @serial.syswrite("^^^SYSBD1#{int_rate}")
      read('OK')
    end

    def set_com2_baud_rate(rate)
      fail(Errors::Argument, 'COM2 can only operate at 19,200') if rate != 19_200

      @serial.syswrite('^^^SYSBD20')
      read('OK')
    end
    # rubocop:enable Style/AccessorMethodName

    def hertz
      @serial.syswrite('^^^RQSHZ')
      read
    end

    def temperature(channel)
      fail(Errors::Argument, 'Invalid temperature channel') unless channel >= 1 && channel <= 8

      @serial.syswrite("^^^APITP#{channel}")
      read
    end

    def enable_temperature_channel(channel)
      fail(Errors::Argument, 'Invalid temperature channel') unless channel >= 1 && channel <= 8

      @serial.syswrite("^^^TMPEN#{channel}")
      read('MOO')
    end

    def recent_values
      @serial.syswrite('^^^APIVAL')
      read
    end

    def send_one_packet
      @serial.syswrite('^^^APISPK')
      read
    end

    private

    def read(expect = nil)
      data = ''

      loop do
        byte = @serial.getbyte

        break unless byte

        data << byte.chr
      end

      p data if @debug
      data.strip!

      fail(Errors::BadData, "Bad data: expected=#{expect} received=#{data}") if !expect.nil? && data != expect

      data
    end
  end
end
