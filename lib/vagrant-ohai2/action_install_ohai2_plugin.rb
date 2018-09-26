require 'vagrant-Ohai2/helpers'

module VagrantPlugins
  module Ohai2
    class ActionInstallOhaiPlugin
      OHAI_PLUGIN_PATH = File.expand_path("../../Ohai2/vagrant.rb", __FILE__)

      include VagrantPlugins::Ohai2::Helpers

      def initialize(app, env)
        @app = app
        @env = env
        @machine = env[:machine]
      end

      def call(env)
        is_chef_used = chef_provisioners.any?
        @app.call(env)
        return unless @machine.communicate.ready?

        if is_chef_used && @machine.config.ohai2.enable
          @machine.ui.info("Installing Ohai2 plugin")
          create_ohai_folders
          copy_ohai_plugin
        end
        if is_chef_used && @machine.config.ohai2.plugins_dir
          @machine.ui.info("Installing Custom Ohai2 plugin")
          create_ohai_folders
          copy_ohai_custom_plugins
        end
      end

      private

      def create_ohai_folders
        @machine.communicate.tap do |comm|
          comm.sudo("mkdir -p /etc/chef/ohai_plugins")
          comm.sudo("chown -R #{@machine.ssh_info[:username]} /etc/chef/ohai_plugins")
        end
      end

      def private_ipv4
        @private_ipv4 ||= @machine.config.vm.networks.find {|network| network.first == :private_network}[1][:ip]
      rescue
        nil
      end

      def vagrant_info
        info = {}
        info[:box] = @machine.config.vm.box
        info[:primary_nic] = @machine.config.Ohai2.primary_nic
        info[:private_ipv4] = private_ipv4
        info
      end

      def copy_ohai_plugin

        hint_file = Tempfile.new(["vagrant-Ohai2", ".json"])
        hint_file.write(vagrant_info.to_json)
        hint_file.close
        @machine.communicate.upload(hint_file.path, "/etc/chef/ohai_plugins/vagrant.json")

        @machine.communicate.upload(OHAI_PLUGIN_PATH, "/etc/chef/ohai_plugins/vagrant.rb")
      end

      def copy_ohai_custom_plugins

        files = Dir.entries(@machine.config.ohai2.plugins_dir).select { |e| e =~ /^[a-z]+\.rb/ }
        files.each do |file|
          custom_ohai2_plugin_path = File.expand_path("#{@machine.config.ohai2.plugins_dir}/#{file}", __FILE__)
          @machine.communicate.upload(custom_ohai2_plugin_path, "/etc/chef/ohai_plugins/#{file}")
        end
      end

    end
  end
end
