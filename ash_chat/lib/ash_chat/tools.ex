defmodule AshChat.Tools do
  @moduledoc """
  AI Tools for chat agents - simplified for basic functionality
  """

  def list() do
    [
      # Return empty list until AshAI tools are properly configured
    ]
  end

  # Simple helper functions for manual tool calling
  def search_messages(_query, _limit \\ 5) do
    {:ok, "Search functionality coming soon when vectorization is enabled"}
  end

  def create_room(title \\ "New Room") do
    case AshChat.Resources.Room.create(%{title: title}) do
      {:ok, room} ->
        {:ok, "Created new room '#{room.title}' with ID: #{room.id}"}
      
      {:error, error} ->
        {:error, "Failed to create room: #{inspect(error)}"}
    end
  end

  def analyze_image(image_url, _analysis_type \\ "describe") do
    {:ok, "Analyzing image at #{image_url}..."}
  end
end