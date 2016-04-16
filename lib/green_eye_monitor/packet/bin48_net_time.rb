require 'green_eye_monitor/packet/bin_net_base'

module GreenEyeMonitor
  module Packet
    class Bin48NetTime < BinNetBase
      default_parameter :version => 0x05
      default_parameter :num_channels => 48
      default_parameter :polarised => true
      default_parameter :has_time => true
    end
  end
end
