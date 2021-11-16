# frozen_string_literal: true
require "shopify_cli"

module Extension
  module Tasks
    module ExecuteCommands
      class Build < Base
        property! :context, accepts: ShopifyCLI::Context
        property! :config_file_name, accepts: String

        def call
          ShopifyCLI::Result.success(merge_server_config)
            .then { |server_config| Models::DevelopmentServer.new.build(server_config) }
            .unwrap do |error|
              raise error unless error.nil?
            end
        end

        private

        def merge_server_config
          Tasks::MergeServerConfig.call(
            context: context,
            file_name: config_file_name,
            type: type
          )
        end
      end
    end
  end
end
