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
    PACKET_FORMATS_REV = PACKET_FORMATS.invert

    BAUD_RATES = {
      19_200  => 0,
      115_200 => 1,
    }

    LONG_CRLF = /\r\n\r\n$/
    CRLF = /\r\n$/

    def initialize(options = {})
      serial_port = options[:serial_port] || '/dev/ttyUSB0'
      baud = options[:baud] || 115_200
      @debug = options[:debug] || false

      @serial = SerialPort.new(serial_port, 'baud' => baud)

      @serial.read_timeout = 100

      # We disable all the push so we can operate in pull mode
      write('SYSOFF')
      write('SYSKAI0')

      # Wait for any last writes
      sleep(0.1)

      # Flush everything
      @serial.flush_output
      @serial.flush_input
    end

    def shell
      old_command = ''

      loop do
        print 'Command: '
        command = STDIN.readline
        command.strip!
        command = old_command if command.empty?
        write("#{command}")
        puts read
        old_command = command
      end
    end

    def disable_realtime
      write('SYSOFF')
      read(:expect => /^OFF$/)
    end

    def enable_realtime
      write('SYS_ON')
      read(:expect => /^_ON$/)
    end

    def disable_keepalive
      write('SYSKAI0')
      read(:expect => /OK$/)
    end

    def enable_keepalive(seconds)
      # 2**x == seconds we aproximate to closest

      x = Math.log2(seconds).round
      x = 7 if x > 7
      x = 1 if x == 0

      write("SYSKAI#{x}")
      read(:expect => /^OK$/)
    end

    def packet_format
      write('RQSRTF')
      format = read(:expect => /^\d\d\r\n$/)

      PACKET_FORMATS_REV[format.to_i]
    end

    def packet_format=(packet_format)
      int_format = PACKET_FORMATS[packet_format] || fail(Errors::Argument, 'Unknown packet format')

      write(format('SYSPKT%02d', int_format))
      read(:expect => /^PKT\r\n$/)
    end

    def secondary_packet_format=(packet_format)
      int_format = PACKET_FORMATS[packet_format] || fail(Errors::Argument, 'Unknown packet format')

      write(format('SYSPKF%02d', int_format))
      read(:expect => 'PKT')
    end

    def disable_secondary_packet_format
      write('SYSPKF00')
      read(:expect => 'PKT')
    end

    def packet_send_interval=(seconds)
      fail(Errors::Argument, 'Invalid interval: must be between 1 and 256') unless seconds > 0 && seconds <= 256

      write(format('SYSIVL%03d', seconds))
      read(:expect => 'IVL')
    end

    def packet_chunk_size=(size)
      fail(Errors::Argument, 'Invalid chunk size: must be between 80 and 65,000') unless size >= 80 && size <= 65_000

      write("SYSPKS#{size}\n")
      read(:expect => 'PKS')
    end

    def packet_chunk_interval=(seconds)
      fail(Errors::Argument, 'Invalid interval: must be between 16 and 65,000') unless seconds >= 16 && seconds <= 65_000

      write("SYSPKI#{seconds}\n")
      read(:expect => 'PKI')
    end

    def max_buffer_size=(size)
      fail(Errors::Argument, 'Invalid buffer size: must be between 10 and 1,700') unless size >= 10 && size <= 1_700

      write("SYSBFF#{size}\n")
      read(:expect => 'BFF')
    end

    def com1_baud_rate=(rate)
      int_rate = BAUD_RATES[rate] || fail(Errors::Argument, 'Unknown baud rate')

      write("SYSBD1#{int_rate}")
      read(:expect => 'OK')
    end

    def com2_baud_rate=(rate)
      fail(Errors::Argument, 'COM2 can only operate at 19,200') if rate != 19_200

      write('SYSBD20')
      read(:expect => 'OK')
    end

    def hertz
      write('RQSHZ')
      read(:expect => /^[56]0Hz\r\n\r\n$/)
    end

    def temperature(channel)
      fail(Errors::Argument, 'Invalid temperature channel') unless channel >= 1 && channel <= 8

      write("APITP#{channel}")
      read(:expect => /\d\d\.\d$/)
    end

    def enable_temperature_channel(channel)
      fail(Errors::Argument, 'Invalid temperature channel') unless channel >= 1 && channel <= 8

      write("TMPEN#{channel}")
      read('MOO')
    end

    def recent_values
      write('APIVAL')
      read(:expect => /VAL.*END\r\n$/)
    end

    def send_one_packet
      pf = packet_format

      write('APISPK')

      case pf
      when :list
        read(:expect => /^.*<EOP>$/, :wait => true)
      else
        fail(Errors::NotImplemented, 'Unimplemented packet format')
      end
    end

    private

    def write(cmd)
      puts "---> #{cmd}" if @debug
      @serial.syswrite("^^^#{cmd}")
    end

    def read_expect(expect)
      data = ''

      loop do
        byte = @serial.getbyte
        puts "DEBUG: byte=#{byte ? byte.chr : byte}" if @debug

        if byte.nil?
          fail(Errors::TooShort, "Data too short #{data.inspect}")
        end

        data << byte.chr

        break if data =~ expect
      end

      data
    end

    def read(options = {})

      if options[:wait]
        data = @serial.getbyte while data.nil?
        @serial.ungetbyte(data)
      end

      if options[:expect]
        data = read_expect(options[:expect])
      else
        fail options.to_s
      end

      puts "<--- #{data.inspect}" if @debug
      data.strip!

      data
    end
  end
end
