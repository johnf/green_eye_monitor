require 'green_eye_monitor/packet/bin_net_base'

module GreenEyeMonitor
  module Packet
    class Bin32Abs < BinNetBase
      default_parameter :version => 0x08
      default_parameter :num_channels => 32
      default_parameter :polarised => false
      default_parameter :has_time => false
    end
  end
end
