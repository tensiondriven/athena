defmodule AthenaCapture.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Event store - durable SQLite storage for all events
      AthenaCapture.EventStore,
      # Event dashboard - the "bell on a string" for activity monitoring
      AthenaCapture.EventDashboard,
      # Conversation monitor for Claude session logs
      AthenaCapture.ConversationMonitor,
      # Screenshot capture for visual documentation
      AthenaCapture.ScreenshotCapture,
      # PTZ camera capture for positioned still images
      AthenaCapture.PTZCameraCapture
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AthenaCapture.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
