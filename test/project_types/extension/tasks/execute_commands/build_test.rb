# frozen_string_literal: true
require "test_helper"

module Extension
  module Tasks
    module ExecuteCommands
      class BuildTest < MiniTest::Test
        def setup
          super
          ShopifyCLI::ProjectType.load_type(:extension)
        end

        def test_error_is_raised_if_error_occurs
          assert_raises StandardError do
            ExecuteCommands::Build.new(
              type: "checkout_ui_extension",
              config_file_name: "test",
              context: TestHelpers::FakeContext.new
            ).call
          end
        end

        private

        def extension
          renderer = Models::ServerConfig::DevelopmentRenderer.new(name: "@shopify/checkout-ui-extensions")
          entries = Models::ServerConfig::DevelopmentEntries.new(main: "src/index.js")
          development = Models::ServerConfig::Development.new(
            build_dir: "test",
            root_dir: "test",
            template: "javascript",
            renderer: renderer,
            entries: entries,
          )

          @extension ||= Models::ServerConfig::Extension.new(
            type: "checkout_ui_extension",
            uuid: "00000000-0000-0000-0000-000000000000",
            user: Models::ServerConfig::User.new,
            development: development
          )
        end
      end
    end
  end
end
