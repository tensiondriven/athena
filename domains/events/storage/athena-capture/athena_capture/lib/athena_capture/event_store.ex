defmodule AthenaCapture.EventStore do
  @moduledoc """
  Durable storage for raw events using SQLite.
  
  Preserves all events to disk for historical analysis and prevents data loss.
  """
  
  use GenServer
  require Logger
  
  defstruct [
    :db_path,
    :db_conn
  ]
  
  @db_path "athena_events.db"
  @batch_size 100
  @flush_interval 5_000  # Flush every 5 seconds
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  def store_event(type, metadata, timestamp \\ nil) do
    timestamp = timestamp || DateTime.utc_now()
    GenServer.cast(__MODULE__, {:store_event, type, metadata, timestamp})
  end
  
  def get_events(opts \\ []) do
    GenServer.call(__MODULE__, {:get_events, opts})
  end
  
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end
  
  def init(_opts) do
    Logger.info("📀 EventStore starting - preserving events to #{@db_path}")
    
    # Initialize SQLite database
    case :esqlite3.open(@db_path) do
      {:ok, conn} ->
        setup_tables(conn)
        schedule_flush()
        
        state = %__MODULE__{
          db_path: @db_path,
          db_conn: conn
        }
        
        {:ok, state}
      
      {:error, reason} ->
        Logger.error("Failed to open SQLite database: #{inspect(reason)}")
        {:stop, reason}
    end
  end
  
  def handle_cast({:store_event, type, metadata, timestamp}, state) do
    json_metadata = Jason.encode!(metadata)
    iso_timestamp = DateTime.to_iso8601(timestamp)
    
    query = """
    INSERT INTO events (type, metadata, timestamp, created_at) 
    VALUES (?, ?, ?, datetime('now'))
    """
    
    case :esqlite3.exec(state.db_conn, query, [type, json_metadata, iso_timestamp]) do
      :ok -> 
        Logger.debug("💾 Stored #{type} event to disk")
        {:noreply, state}
      {:error, reason} ->
        Logger.warning("Failed to store event: #{inspect(reason)}")
        {:noreply, state}
    end
  end
  
  def handle_call({:get_events, opts}, _from, state) do
    limit = Keyword.get(opts, :limit, 100)
    since = Keyword.get(opts, :since)
    
    base_query = "SELECT * FROM events"
    
    {query, params} = case since do
      nil -> 
        {"#{base_query} ORDER BY created_at DESC LIMIT ?", [limit]}
      timestamp ->
        iso_since = DateTime.to_iso8601(timestamp)
        {"#{base_query} WHERE timestamp >= ? ORDER BY created_at DESC LIMIT ?", [iso_since, limit]}
    end
    
    case :esqlite3.exec(state.db_conn, query, params) do
      {:ok, results} ->
        events = parse_event_results(results)
        {:reply, {:ok, events}, state}
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end
  
  def handle_call(:get_stats, _from, state) do
    queries = [
      {"total_events", "SELECT COUNT(*) FROM events"},
      {"event_types", "SELECT type, COUNT(*) as count FROM events GROUP BY type ORDER BY count DESC"},
      {"recent_events", "SELECT COUNT(*) FROM events WHERE timestamp >= datetime('now', '-1 hour')"}
    ]
    
    stats = Enum.reduce(queries, %{}, fn {key, query}, acc ->
      case :esqlite3.exec(state.db_conn, query) do
        {:ok, results} -> Map.put(acc, key, results)
        {:error, _} -> Map.put(acc, key, "error")
      end
    end)
    
    {:reply, stats, state}
  end
  
  def handle_info(:flush, state) do
    # Periodic flush - SQLite handles this automatically but we can add explicit sync
    :esqlite3.exec(state.db_conn, "PRAGMA synchronous = NORMAL")
    schedule_flush()
    {:noreply, state}
  end
  
  defp setup_tables(conn) do
    create_table_sql = """
    CREATE TABLE IF NOT EXISTS events (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type TEXT NOT NULL,
      metadata TEXT NOT NULL,
      timestamp TEXT NOT NULL,
      created_at TEXT NOT NULL
    );
    
    CREATE INDEX IF NOT EXISTS idx_events_type ON events(type);
    CREATE INDEX IF NOT EXISTS idx_events_timestamp ON events(timestamp);
    CREATE INDEX IF NOT EXISTS idx_events_created_at ON events(created_at);
    """
    
    case :esqlite3.exec(conn, create_table_sql) do
      :ok -> 
        Logger.info("📀 Event storage tables ready")
        :ok
      {:error, reason} ->
        Logger.error("Failed to create tables: #{inspect(reason)}")
        {:error, reason}
    end
  end
  
  defp schedule_flush do
    Process.send_after(self(), :flush, @flush_interval)
  end
  
  defp parse_event_results({columns, rows}) do
    Enum.map(rows, fn row ->
      columns
      |> Enum.zip(row)
      |> Map.new()
      |> parse_event_row()
    end)
  end
  
  defp parse_event_row(row) do
    metadata = case Jason.decode(row["metadata"]) do
      {:ok, parsed} -> parsed
      {:error, _} -> %{}
    end
    
    %{
      id: row["id"],
      type: row["type"],
      metadata: metadata,
      timestamp: row["timestamp"],
      created_at: row["created_at"]
    }
  end
end