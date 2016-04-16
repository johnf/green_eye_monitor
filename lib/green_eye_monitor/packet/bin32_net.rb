require 'green_eye_monitor/packet/bin_net_base'

module GreenEyeMonitor
  module Packet
    class Bin32Net < BinNetBase
      default_parameter :version => 0x07
      default_parameter :num_channels => 32
      default_parameter :polarised => true
      default_parameter :has_time => false
    end
  end
end
