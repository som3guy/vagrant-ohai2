require "vagrant-ohai2/version"
require "vagrant/plugin"

raise RuntimeError, "vagrant-Ohai2 will only work with Vagrant 1.2.3 and above!" if Vagrant::VERSION <= "1.2.3"

module VagrantPlugins
  module Ohai2
    class Plugin < Vagrant.plugin("2")
      name "vagrant-ohai2"
      description <<-DESC
      This plugin ensures ipaddress and cloud attributes in Chef
      correspond to Vagrant's private network
      DESC

      action_hook(:install_ohai2_plugin, Plugin::ALL_ACTIONS) do |hook|
        require_relative 'action_install_ohai2_plugin'
        require_relative 'action_configure_chef'
        hook.after(Vagrant::Action::Builtin::Provision, ActionInstallOhaiPlugin)
        hook.before(Vagrant::Action::Builtin::ConfigValidate, ActionConfigureChef)
      end

      config(:ohai2) do
        require_relative "config"
        Config
      end
    end
  end
end
