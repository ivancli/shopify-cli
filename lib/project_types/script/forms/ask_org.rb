# frozen_string_literal: true

module Script
  module Forms
    class AskOrg < ShopifyCLI::Form
      attr_accessor :org
      
      def ask
        orgs = @xargs
        if orgs.count == 1
          default = orgs.first
          ctx.puts(ctx.message("script.application.ensure_env.organization", default["businessName"],
            default["id"]))
          self.org = default
        elsif orgs.count > 0
          CLI::UI::Prompt.ask(ctx.message("script.application.ensure_env.organization_select")) do |handler|
            orgs.each do |org|
              handler.option("#{org["businessName"]} (#{org["id"]})") { self.org = org }
            end
          end
        else
          raise Errors::NoExistingOrganizationsError
        end
      end

      # copied from lib/shopify_cli/task.rb
      # should probably just invoke it directly from there
      def self.wants_to_run_against_shopify_org?(ctx: ctx)
        ctx.puts(ctx.message("core.tasks.select_org_and_shop.identified_as_shopify"))
        message = ctx.message("core.tasks.select_org_and_shop.first_party")
        CLI::UI::Prompt.confirm(message, default: false)
      end

    end

  end

end