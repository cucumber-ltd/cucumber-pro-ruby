require 'rbconfig'
require 'etc'
require 'cucumber/platform'

module Cucumber
  module Pro
    class Info
      def to_h
        {
          os: "#{RbConfig::CONFIG['host_os']} (#{RbConfig::CONFIG['host_cpu']})",
          platform_version: "#{RbConfig::CONFIG['ruby_install_name']} #{RbConfig::CONFIG['ruby_version']}",
          tool_version: "cucumber-ruby #{Cucumber::VERSION}}",
          os_user: Etc.getlogin,
          client_version: "cucumber-pro-ruby #{File.read(File.dirname(__FILE__) + '/version').strip}" 
        }
      end
    end
  end
end
