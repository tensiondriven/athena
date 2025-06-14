defmodule AshChatWeb.Router do
  use AshChatWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {AshChatWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", AshChatWeb do
    pipe_through :browser

    live "/", ChatLive  # Default to chat
    live "/chat", ChatLive
    live "/chat/:room_id", ChatLive
    live "/events", EventDashboardLive
    live "/system", SystemDashboardLive
    live "/settings", ProfilesLive  # Rename profiles to settings for consistency
    live "/prompt-visualizer", PromptVisualizerLive
  end

  # API routes for event collection
  scope "/api", AshChatWeb do
    pipe_through :api

    post "/events", EventController, :create
    get "/events/health", EventController, :health
    get "/events/stats", EventController, :stats
  end

  # Webhook endpoint for collectors (compatibility with existing collector config)
  scope "/webhook", AshChatWeb do
    pipe_through :api

    post "/test", EventController, :create
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:ash_chat, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: AshChatWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
