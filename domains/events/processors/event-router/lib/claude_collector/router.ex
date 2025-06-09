defmodule ClaudeCollector.Router do
  use Plug.Router
  require Logger

  plug Plug.Logger
  plug :match
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :dispatch

  get "/health" do
    stats = ClaudeCollector.Statistics.get_stats()
    
    response = %{
      status: "healthy",
      service: "claude_collector",
      version: "0.1.0",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      stats: stats
    }
    
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(response))
  end

  get "/stats" do
    stats = ClaudeCollector.Statistics.get_stats()
    
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(stats))
  end

  post "/webhook/test" do
    # Test endpoint for manual event injection
    event = %{
      id: UUID.uuid4(),
      type: "test_event",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      source: "test_webhook",
      file_path: "test",
      content: conn.body_params,
      metadata: %{
        remote_ip: to_string(:inet.ntoa(conn.remote_ip))
      }
    }
    
    ClaudeCollector.EventPublisher.publish_event(event)
    
    Logger.info("Test event published: #{event.id}")
    
    response = %{
      message: "Test event published",
      event_id: event.id
    }
    
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(202, Jason.encode!(response))
  end

  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{error: "Not found"}))
  end
end
