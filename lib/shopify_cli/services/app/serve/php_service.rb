module ShopifyCLI
  module Services
    module App
      module Serve
        class PHPService < BaseService
          attr_accessor :host, :port, :context, :session_domain, :login_path, :callback_path

          def initialize(host:, port:, context:)
            @host = host
            @port = port
            @context = context
            super()
          end

          def call
            project = ShopifyCLI::Project.current
            url = host || ShopifyCLI::Tunnel.start(context, port: port)
            raise ShopifyCLI::Abort,
              context.message("core.app.serve.error.host_must_be_https") if url.match(/^https/i).nil?
            project.env.update(context, :host, url)
            domain = URI(url)
            project.env.update(context, :session_domain, domain.hostname)

            ShopifyCLI::Tasks::UpdateDashboardURLS.call(
              context,
              url: url,
              callback_url: project.env.callback_path,
            )

            if project.env.shop
              project_url = "#{project.env.host}#{project.env.login_path}?shop=#{project.env.shop}"
              context.puts("\n" + context.message("core.app.serve.open_info", project_url) + "\n")
            end

            CLI::UI::Frame.open(context.message("core.app.serve.running_server")) do
              if ShopifyCLI::ProcessSupervision.running?(:npm_watch)
                ShopifyCLI::ProcessSupervision.stop(:npm_watch)
              end
              ShopifyCLI::ProcessSupervision.start(:npm_watch, "npm run watch", force_spawn: true)

              env = project.env.to_h
              context.system("php", "artisan", "serve", "--port", port.to_s, env: env)
            end
          end
        end
      end
    end
  end
end
