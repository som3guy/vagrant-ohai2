require 'vagrant-ohai2/helpers'

module VagrantPlugins
  module Ohai2
    class ActionConfigureChef
      include VagrantPlugins::Ohai2::Helpers

      def initialize(app, env)
        @app = app
        @env = env
        @machine = env[:machine]
        register_custom_chef_config
      end

      def call(env)
        @app.call(env)
      end

      private
      def ohai2_custom_config(current_conf)
        tmp = Tempfile.new(["chef-custom-config", ".rb"])
        tmp.puts 'ohai.plugin_path << "/etc/chef/ohai_plugins"'
        tmp.write(File.read(current_conf)) if current_conf
        tmp.close
        tmp
      end

      def register_custom_chef_config
        return unless @machine.config.ohai2.enable or @machine.config.ohai2.plugins_dir
        chef_provisioners.each do |provisioner|
          if provisioner.config.respond_to? :custom_config_path and not provisioner.config.custom_config_path == Plugin::UNSET_VALUE
            current_custom_config_path = provisioner.config.custom_config_path
          else
            current_custom_config_path = nil
          end
          custom_config = ohai2_custom_config(current_custom_config_path)
          provisioner.config.instance_variable_set("@custom_config_path", custom_config.path)
          # retain a reference to prevent tempfile from being auto cleaned up
          provisioner.config.instance_variable_set("@__custom_config_tempfile__", custom_config)
        end
      end
    end
  end
end
