defmodule AshChat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AshChatWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:ash_chat, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AshChat.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: AshChat.Finch},
      # Start the Room Conversation Supervisor for managing agent workers
      AshChat.AI.RoomConversationSupervisor,
      # Start the Message Event Processor for autonomous agent conversations
      AshChat.AI.MessageEventProcessor,
      # Start a worker by calling: AshChat.Worker.start_link(arg)
      # {AshChat.Worker, arg},
      # Start to serve requests, typically the last entry
      AshChatWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AshChat.Supervisor]
    
    # Start the supervisor
    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        # Initialize demo data after the supervisor starts
        Task.start(fn ->
          # Give the system a moment to fully initialize
          Process.sleep(1000)
          
          # Check if we need to initialize demo data
          if Enum.empty?(AshChat.Resources.Room.read!()) do
            IO.puts("Initializing demo data...")
            AshChat.Setup.reset_demo_data()
          else
            IO.puts("Demo data already exists, skipping initialization")
          end
        end)
        
        {:ok, pid}
        
      error ->
        error
    end
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AshChatWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
