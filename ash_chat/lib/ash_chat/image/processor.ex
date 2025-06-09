defmodule AshChat.Image.Processor do
  @moduledoc """
  Module for reading and processing images from various backend locations at intervals
  """

  use GenServer
  require Logger

  alias AshChat.AI.ChatAgent

  @default_interval 5_000  # 5 seconds

  defstruct [
    :interval,
    :sources,
    :chat_id,
    :enabled
  ]

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    interval = Keyword.get(opts, :interval, @default_interval)
    sources = Keyword.get(opts, :sources, [])
    chat_id = Keyword.get(opts, :chat_id)
    enabled = Keyword.get(opts, :enabled, true)

    state = %__MODULE__{
      interval: interval,
      sources: sources,
      chat_id: chat_id,
      enabled: enabled
    }

    if enabled do
      schedule_next_check(interval)
    end

    {:ok, state}
  end

  def handle_info(:check_images, state) do
    if state.enabled do
      process_image_sources(state.sources, state.chat_id)
      schedule_next_check(state.interval)
    end

    {:noreply, state}
  end

  def configure_sources(sources) when is_list(sources) do
    GenServer.cast(__MODULE__, {:configure_sources, sources})
  end

  def set_chat_id(chat_id) do
    GenServer.cast(__MODULE__, {:set_chat_id, chat_id})
  end

  def enable() do
    GenServer.cast(__MODULE__, :enable)
  end

  def disable() do
    GenServer.cast(__MODULE__, :disable)
  end

  def handle_cast({:configure_sources, sources}, state) do
    {:noreply, %{state | sources: sources}}
  end

  def handle_cast({:set_chat_id, chat_id}, state) do
    {:noreply, %{state | chat_id: chat_id}}
  end

  def handle_cast(:enable, state) do
    if not state.enabled do
      schedule_next_check(state.interval)
    end
    {:noreply, %{state | enabled: true}}
  end

  def handle_cast(:disable, state) do
    {:noreply, %{state | enabled: false}}
  end

  defp schedule_next_check(interval) do
    Process.send_after(self(), :check_images, interval)
  end

  defp process_image_sources(sources, chat_id) when is_binary(chat_id) do
    Enum.each(sources, fn source ->
      try do
        process_image_source(source, chat_id)
      rescue
        error ->
          Logger.error("Failed to process image source #{inspect(source)}: #{inspect(error)}")
      end
    end)
  end

  defp process_image_sources(_sources, _chat_id), do: :ok

  defp process_image_source(%{type: :file_system, path: path, pattern: pattern}, chat_id) do
    case File.ls(path) do
      {:ok, files} ->
        image_files = 
          files
          |> Enum.filter(&matches_pattern?(&1, pattern))
          |> Enum.filter(&is_image_file?/1)
          |> Enum.take(1)  # Process one image at a time

        Enum.each(image_files, fn file ->
          file_path = Path.join(path, file)
          process_file_image(file_path, chat_id)
        end)

      {:error, reason} ->
        Logger.warning("Could not read directory #{path}: #{reason}")
    end
  end

  defp process_image_source(%{type: :url, urls: urls}, chat_id) when is_list(urls) do
    Enum.each(urls, fn url ->
      case HTTPoison.get(url) do
        {:ok, %{status_code: 200, body: _body}} ->
          send_image_to_chat(chat_id, "Image from #{url}", url)

        {:error, reason} ->
          Logger.warning("Failed to fetch image from #{url}: #{reason}")
      end
    end)
  end

  defp process_image_source(%{type: :s3, bucket: bucket, prefix: prefix}, _chat_id) do
    # Placeholder for S3 integration
    Logger.info("S3 image processing not yet implemented for bucket: #{bucket}, prefix: #{prefix}")
    # TODO: Implement S3 image fetching using ExAws or similar
  end

  defp process_image_source(%{type: :database, query: query}, _chat_id) do
    # Placeholder for database image processing
    Logger.info("Database image processing not yet implemented for query: #{query}")
    # TODO: Implement database image fetching
  end

  defp process_image_source(source, _chat_id) do
    Logger.warning("Unknown image source type: #{inspect(source)}")
  end

  defp process_file_image(file_path, chat_id) do
    case File.read(file_path) do
      {:ok, image_data} ->
        # For now, we'll create a data URL. In production, you might want to upload to a CDN
        mime_type = get_mime_type(file_path)
        data_url = "data:#{mime_type};base64,#{Base.encode64(image_data)}"
        
        send_image_to_chat(chat_id, "New image from #{Path.basename(file_path)}", data_url)

      {:error, reason} ->
        Logger.warning("Could not read image file #{file_path}: #{reason}")
    end
  end

  defp send_image_to_chat(chat_id, content, image_url) do
    Task.start(fn ->
      case ChatAgent.process_multimodal_message(chat_id, content, image_url) do
        {:ok, _message} ->
          # Broadcast to LiveView
          Phoenix.PubSub.broadcast(
            AshChat.PubSub,
            "chat:#{chat_id}",
            {:message_processed}
          )

        {:error, error} ->
          Logger.error("Failed to process image message: #{error}")
      end
    end)
  end

  defp matches_pattern?(filename, pattern) when is_binary(pattern) do
    String.contains?(filename, pattern)
  end

  defp matches_pattern?(filename, pattern) when is_struct(pattern, Regex) do
    Regex.match?(pattern, filename)
  end

  defp matches_pattern?(_filename, _pattern), do: true

  defp is_image_file?(filename) do
    ext = 
      filename
      |> Path.extname()
      |> String.downcase()

    ext in [".jpg", ".jpeg", ".png", ".gif", ".bmp", ".webp", ".svg"]
  end

  defp get_mime_type(file_path) do
    case Path.extname(file_path) |> String.downcase() do
      ".jpg" -> "image/jpeg"
      ".jpeg" -> "image/jpeg"
      ".png" -> "image/png"
      ".gif" -> "image/gif"
      ".bmp" -> "image/bmp"
      ".webp" -> "image/webp"
      ".svg" -> "image/svg+xml"
      _ -> "image/jpeg"  # default
    end
  end

  # Public API for configuring image sources
  def add_file_system_source(path, pattern \\ "*") do
    source = %{type: :file_system, path: path, pattern: pattern}
    current_sources = GenServer.call(__MODULE__, :get_sources)
    configure_sources([source | current_sources])
  end

  def add_url_source(urls) when is_list(urls) do
    source = %{type: :url, urls: urls}
    current_sources = GenServer.call(__MODULE__, :get_sources)
    configure_sources([source | current_sources])
  end

  def add_s3_source(bucket, prefix \\ "") do
    source = %{type: :s3, bucket: bucket, prefix: prefix}
    current_sources = GenServer.call(__MODULE__, :get_sources)
    configure_sources([source | current_sources])
  end

  def handle_call(:get_sources, _from, state) do
    {:reply, state.sources, state}
  end
end