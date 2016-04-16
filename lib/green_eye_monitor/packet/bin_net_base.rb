require 'bindata'

module GreenEyeMonitor
  module Packet
    class BinNetBase < BinData::Record
      uint8 :header_a, :asserted_value => 0xFE
      uint8 :header_b, :asserted_value => 0xFF
      uint8 :header_c, :asserted_value => :version

      uint16be :raw_voltage

      array :abs_watt_seconds, :type => :uint40le, :initial_length => :num_channels
      array :polarised_watt_seconds, :type => :uint40le, :initial_length => :num_channels, :onlyif => :polarised

      uint16be :serial
      skip :length => 1
      uint8 :device_id

      array :raw_current, :type => :uint16le, :initial_length => :num_channels

      uint24le :seconds

      array :pulse, :type => :uint24le, :initial_length => 4
      array :raw_temperature, :type => :uint16le, :initial_length => 8
      skip :length => 2, :onlyif => lambda { num_channels == 32 }

      struct :time, :onlyif => :has_time do
        uint8 :year
        uint8 :month
        uint8 :day
        uint8 :hour
        uint8 :minute
        uint8 :second
      end

      uint8 :footer_a, :asserted_value => 0xFF
      uint8 :footer_b, :asserted_value => 0xFE

      uint8 :checksum, :assert => lambda { calc_checksum(value) }

      def calc_checksum(checksum)
        calculated_checksum = (to_binary_s.bytes.inject(0, :+) - checksum) & 0xFF

        # TODO why are we off by one?
        checksum == calculated_checksum + 1
      end

      def voltage
        raw_voltage / 10.0
      end

      def current
        raw_current.map { |v| v / 50.0 }
      end

      def temperature
        raw_temperature.map { |v| v / 2.0 }
      end

      def serial_number
        format('%03d%05d', device_id, serial)
      end
    end
  end
end
