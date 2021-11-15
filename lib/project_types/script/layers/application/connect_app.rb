# frozen_string_literal: true

require "shopify_cli"

module Script
  module Layers
    module Application
      class ConnectApp
        class << self

          def call(ctx:)
            if ShopifyCLI::Shopifolk.check && Forms::AskOrg.wants_to_run_against_shopify_org?(ctx: ctx)
              ShopifyCLI::Shopifolk.act_as_shopify_organization
            end

            # establish env
            orgs = ShopifyCLI::PartnersAPI::Organizations.fetch_with_app(ctx)
            org = 
              if partner_proxy_bypass
                stubbed_org
              else
                Forms::AskOrg.ask(ctx, orgs, nil).org
              end

            app = Forms::AskApp.ask(ctx, org["apps"], nil).app

            script_project_repo = Layers::Infrastructure::ScriptProjectRepository.new(ctx: ctx)
            script_project = script_project_repo.get
            extension_point_type = script_project.extension_point_type
            
            script_service = Layers::Infrastructure::ServiceLocator.script_service(ctx: ctx, api_key: app["apiKey"])
            scripts = script_service.get_app_scripts(extension_point_type: extension_point_type)

            uuid = Forms::AskScriptUuid.ask(ctx, scripts, nil).uuid

            # connect to new app
            script_project_repo.create_env(
              api_key: app["apiKey"],
              secret: app["apiSecretKeys"].first["secret"],
              uuid: uuid
            )
          end

          # def wants_to_run_against_shopify_org?(ctx)
          #   @ctx = ctx
          #   @ctx.puts(@ctx.message("core.tasks.select_org_and_shop.identified_as_shopify"))
          #   message = @ctx.message("core.tasks.select_org_and_shop.first_party")
          #   CLI::UI::Prompt.confirm(message, default: false)
          # end

          # def call(script_project_repo:, api_key:, secret:, uuid:)
          #   script_project_repo.create_env(
          #     api_key: api_key,
          #     secret: secret,
          #     uuid: uuid
          #   )
          # end

          def env_valid?(ctx:)
            script_project_repo = Layers::Infrastructure::ScriptProjectRepository.new(ctx: ctx)
            script_project = script_project_repo.get
            return true if script_project.api_key && script_project.api_secret && script_project.uuid_defined?
            false
          end

          private

          def partner_proxy_bypass
            !ENV["BYPASS_PARTNERS_PROXY"].nil?
          end

          def stubbed_org
            {
              "apps" => [
                {
                  "appType" => "custom",
                  "apiKey" => "stubbed-api-key",
                  "apiSecretKeys" => [{ "secret" => "stubbed-api-secret" }],
                  "title" => "Fake App (Not connected to Partners)",
                },
              ],
            }
          end
          
        end
      end
    end
  end
end
