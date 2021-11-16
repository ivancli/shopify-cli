# frozen_string_literal: true
require "shopify_cli"

module Extension
  module Tasks
    module ExecuteCommands
      class Serve < Base
        property! :context, accepts: ShopifyCLI::Context
        property! :config_file_name, accepts: String
        property  :port, accepts: Integer, default: 39351
        property  :resource_url, accepts: String
        property! :tunnel_url, accepts: String

        def call
          ShopifyCLI::Result.success(merge_server_config)
            .then { |server_config| Models::DevelopmentServer.new.serve(context, server_config) }
            .unwrap do |error|
              raise error unless error.nil?
            end
        end

        private

        def merge_server_config
          Tasks::MergeServerConfig.call(
            context: context,
            file_name: config_file_name,
            port: port,
            resource_url: resource_url,
            tunnel_url: tunnel_url,
            type: type
          )
        end
      end
    end
  end
end
