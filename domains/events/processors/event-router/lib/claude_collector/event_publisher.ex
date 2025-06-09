defmodule ClaudeCollector.EventPublisher do
  use Broadway
  require Logger

  alias Broadway.Message

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {ClaudeCollector.EventProducer, []},
        transformer: {__MODULE__, :transform, []},
        concurrency: 1
      ],
      processors: [
        default: [concurrency: 10]
      ],
      batchers: [
        athena: [
          concurrency: 5,
          batch_size: 50,
          batch_timeout: 5_000
        ]
      ]
    )
  end

  def publish_event(event) do
    ClaudeCollector.EventProducer.publish(event)
  end

  def transform(event, _opts) do
    %Message{
      data: event,
      acknowledger: {__MODULE__, :ack_id, :ack_data},
      batcher: :athena
    }
  end

  def ack(:ack_id, successful, failed) do
    Logger.debug("Acknowledged #{length(successful)} successful, #{length(failed)} failed messages")
  end

  @impl true
  def handle_message(_, message, _) do
    # Enhance the event with additional metadata
    enhanced_event = enhance_event(message.data)
    
    # Update statistics
    ClaudeCollector.Statistics.increment_processed()
    
    # Store in Neo4j knowledge graph
    store_in_knowledge_graph(enhanced_event)
    
    message
  end

  @impl true
  def handle_batch(:athena, messages, _batch_info, _context) do
    events = Enum.map(messages, & &1.data)
    
    Logger.info("Publishing batch of #{length(events)} events to athena-ingest")
    
    case forward_to_athena(events) do
      {:ok, _response} ->
        ClaudeCollector.Statistics.increment_published(length(events))
        messages
      
      {:error, reason} ->
        Logger.error("Failed to publish batch to athena-ingest: #{inspect(reason)}")
        ClaudeCollector.Statistics.increment_failed(length(events))
        
        # Mark messages as failed for potential retry
        Enum.map(messages, &Broadway.Message.failed(&1, reason))
    end
  end

  defp enhance_event(event) do
    Map.merge(event, %{
      processed_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      collector_version: "0.1.0",
      processing_metadata: %{
        hostname: System.get_env("HOSTNAME", "unknown"),
        pid: inspect(self())
      }
    })
  end

  defp store_in_knowledge_graph(event) do
    try do
      # Create cypher query to store chat event
      cypher = """
      MERGE (session:ChatSession {source: $source})
      CREATE (event:ChatEvent {
        id: $id,
        type: $type,
        timestamp: datetime($timestamp),
        file_path: $file_path,
        content_summary: $content_summary,
        processed_at: datetime($processed_at)
      })
      CREATE (session)-[:HAS_EVENT]->(event)
      RETURN event.id as event_id
      """
      
      params = %{
        source: event.source,
        id: event.id,
        type: event.type,
        timestamp: event.timestamp,
        file_path: event.file_path,
        content_summary: extract_content_summary(event.content),
        processed_at: event.processed_at
      }
      
      case Bolt.Sips.query(Bolt.Sips.conn(), cypher, params) do
        {:ok, _result} ->
          Logger.debug("Stored event #{event.id} in knowledge graph")
        
        {:error, reason} ->
          Logger.error("Failed to store event in knowledge graph: #{inspect(reason)}")
      end
    rescue
      e ->
        Logger.error("Error storing in knowledge graph: #{inspect(e)}")
    end
  end

  defp extract_content_summary(content) when is_map(content) do
    # Extract meaningful summary from chat content
    cond do
      Map.has_key?(content, "messages") ->
        messages = content["messages"]
        "Chat with #{length(messages)} messages"
      
      Map.has_key?(content, "conversation") ->
        "Conversation data"
      
      Map.has_key?(content, "raw_text") ->
        text = content["raw_text"]
        if String.length(text) > 100 do
          String.slice(text, 0, 100) <> "..."
        else
          text
        end
      
      true ->
        "Unknown content structure"
    end
  end

  defp extract_content_summary(_), do: "Non-map content"

  defp forward_to_athena(events) do
    endpoint = System.get_env("ATHENA_ENDPOINT", "http://athena-capture:8080/events")
    
    payload = %{
      source: "claude_collector",
      events: events,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }
    
    headers = [{"Content-Type", "application/json"}]
    body = Jason.encode!(payload)
    
    case HTTPoison.post(endpoint, body, headers, timeout: 30_000) do
      {:ok, %HTTPoison.Response{status_code: code}} when code in 200..299 ->
        {:ok, :published}
      
      {:ok, response} ->
        {:error, "HTTP #{response.status_code}: #{response.body}"}
      
      {:error, reason} ->
        {:error, reason}
    end
  end
end