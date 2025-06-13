defmodule AshChatWeb.FlashLogger do
  @moduledoc """
  Logs error flash messages to a separate file for monitoring
  """
  
  require Logger
  
  @flash_log_path "tmp/flash_errors.log"
  
  def log_flash_error(message, metadata \\ %{}) do
    timestamp = DateTime.utc_now() |> DateTime.to_string()
    
    # Format the log entry
    log_entry = %{
      timestamp: timestamp,
      type: "flash_error",
      message: message,
      metadata: metadata
    }
    
    # Write to flash error log
    write_to_log(log_entry)
    
    # Also log to regular logger for debugging
    Logger.warning("Flash Error: #{message}", metadata)
  end
  
  def log_flash_info(message, metadata \\ %{}) do
    # We could log info messages too if needed
    Logger.info("Flash Info: #{message}", metadata)
  end
  
  defp write_to_log(entry) do
    # Ensure directory exists
    File.mkdir_p!(Path.dirname(@flash_log_path))
    
    # Format as JSON for easy parsing
    log_line = Jason.encode!(entry) <> "\n"
    
    # Append to log file
    File.write!(@flash_log_path, log_line, [:append])
  end
  
  @doc """
  Clear the flash error log
  """
  def clear_log do
    case File.rm(@flash_log_path) do
      :ok -> :ok
      {:error, :enoent} -> :ok
      error -> error
    end
  end
end