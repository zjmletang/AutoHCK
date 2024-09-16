# typed: true
# frozen_string_literal: true

module AutoHCK
  class QemuHCK
    module Devices
      extend T::Sig

      sig { params(logger: AutoHCK::MultiLogger).returns(Models::QemuHCKDevice) }
      def self.iommu(logger)
        cpuinfo = File.read('/proc/cpuinfo')
        vendor_match = cpuinfo.match(/^vendor_id\s*:\s*(\S+)/)

        vendor =
          if vendor_match
            vendor_match[1]
          else
            logger.fatal('Could not determine CPU vendor')
            exit 1
          end

        case vendor
        when 'GenuineIntel'
          Models::QemuHCKDevice.from_json_file("#{__dir__}/intel-iommu.json", logger)
        when 'AuthenticAMD'
          Models::QemuHCKDevice.from_json_file("#{__dir__}/amd-iommu.json", logger)
        else
          logger.fatal("Unknown CPU vendor: #{vendor}")
          exit 1
        end
      end
    end
  end
end
