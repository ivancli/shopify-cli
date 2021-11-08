# frozen_string_literal: true

require "shopify_cli"

module Script
  module Layers
    module Application
      class ConnectApp
        class << self
          attr_accessor :ctx

          def call(ctx:, against_shopify_org:)
            self.ctx = ctx

            script_project_repo = Layers::Infrastructure::ScriptProjectRepository.new(ctx: ctx)
            script_project = script_project_repo.get

            org = ask_org(against_shopify_org)
            app = ask_app(org["apps"])
            uuid = ask_script_uuid(app, script_project.extension_point_type)

            return false if script_project.api_key && script_project.api_secret && script_project.uuid_defined?

            script_project_repo.create_env(
              api_key: app["apiKey"],
              secret: app["apiSecretKeys"].first["secret"],
              uuid: uuid
            )

            true
          end

          private

          def ask_org(against_shopify_org)
            return stubbed_org if partner_proxy_bypass

            if ShopifyCLI::Shopifolk.check && against_shopify_org
              ShopifyCLI::Shopifolk.act_as_shopify_organization
            end

            orgs = ShopifyCLI::PartnersAPI::Organizations.fetch_with_app(ctx)
            if orgs.count == 1
              default = orgs.first
              ctx.puts(ctx.message("script.application.ensure_env.organization", default["businessName"],
                default["id"]))
              default
            elsif orgs.count > 0
              CLI::UI::Prompt.ask(ctx.message("script.application.ensure_env.organization_select")) do |handler|
                orgs.each do |org|
                  handler.option("#{org["businessName"]} (#{org["id"]})") { org }
                end
              end
            else
              raise Errors::NoExistingOrganizationsError
            end
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

          def partner_proxy_bypass
            !ENV["BYPASS_PARTNERS_PROXY"].nil?
          end

          def ask_app(apps)
            unless ShopifyCLI::Shopifolk.acting_as_shopify_organization?
              apps = apps.select { |app| app["appType"] == "custom" }
            end

            if apps.count == 1
              default = apps.first
              ctx.puts(ctx.message("script.application.ensure_env.app", default["title"]))
              default
            elsif apps.count > 0
              CLI::UI::Prompt.ask(ctx.message("script.application.ensure_env.app_select")) do |handler|
                apps.each do |app|
                  handler.option(app["title"]) { app }
                end
              end
            else
              raise Errors::NoExistingAppsError
            end
          end

          def ask_script_uuid(app, extension_point_type)
            # current
            script_service = Layers::Infrastructure::ServiceLocator.script_service(ctx: ctx, api_key: app["apiKey"])
            scripts = script_service.get_app_scripts(extension_point_type: extension_point_type)

            # from exploratory branch
            # script_service = Layers::Infrastructure::ScriptService.new(ctx: ctx)
            # scripts = script_service.get_app_scripts(api_key: app["apiKey"], extension_point_type: extension_point_type)

            return nil unless scripts.count > 0 &&
              CLI::UI::Prompt.confirm(ctx.message("script.application.ensure_env.ask_connect_to_existing_script"))

            CLI::UI::Prompt.ask(ctx.message("script.application.ensure_env.ask_which_script_to_connect_to")) do |handler|
              scripts.each do |script|
                handler.option("#{script["title"]} (#{script["uuid"]})") { script["uuid"] }
              end
            end
          end
        end
      end
    end
  end
end
