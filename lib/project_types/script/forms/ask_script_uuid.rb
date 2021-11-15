# frozen_string_literal: true

module Script
  module Forms
    class AskScriptUuid < ShopifyCLI::Form
      attr_accessor :uuid
      def ask
        scripts = @xargs
        return nil unless scripts.count > 0 &&
          CLI::UI::Prompt.confirm(ctx.message("script.application.ensure_env.ask_connect_to_existing_script"))

        CLI::UI::Prompt.ask(ctx.message("script.application.ensure_env.ask_which_script_to_connect_to")) do |handler|
          scripts.each do |script|
            handler.option("#{script["title"]} (#{script["uuid"]})") { self.uuid = script["uuid"] }
          end
        end
      end
    end
  end
end