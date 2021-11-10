# frozen_string_literal: true

require "shopify_cli"

module Script
  module Layers
    module Application
      class ConnectApp
        class << self
          attr_accessor :ctx

          def call(ctx:, app:, uuid:)
            self.ctx = ctx
            script_project_repo = Layers::Infrastructure::ScriptProjectRepository.new(ctx: ctx)
            script_project = script_project_repo.get
            return false if script_project.api_key && script_project.api_secret && script_project.uuid_defined?

            script_project_repo.create_env(
              api_key: app["apiKey"],
              secret: app["apiSecretKeys"].first["secret"],
              uuid: uuid
            )

            true
          end
        end
      end
    end
  end
end
