defmodule AthenaCapture do
  @moduledoc """
  AthenaCapture provides structured event capture for visual documentation and monitoring.
  
  Supports multiple capture types:
  - Screenshots (full screen, active window, interactive selection)
  - PTZ camera stills (with positioning)
  - Conversation monitoring
  
  All events are stored durably and feed into the athena knowledge graph pipeline.
  """

  # Screenshot API
  defdelegate capture_screen(opts \\ []), to: AthenaCapture.ScreenshotCapture
  defdelegate capture_window(window_id, opts \\ []), to: AthenaCapture.ScreenshotCapture
  defdelegate capture_active_window(opts \\ []), to: AthenaCapture.ScreenshotCapture
  defdelegate capture_interactive(opts \\ []), to: AthenaCapture.ScreenshotCapture

  # PTZ Camera API
  defdelegate capture_ptz_with_position(position_opts, capture_opts \\ []), to: AthenaCapture.PTZCameraCapture, as: :capture_with_position
  defdelegate capture_ptz_current(opts \\ []), to: AthenaCapture.PTZCameraCapture, as: :capture_current_position
  defdelegate position_ptz_camera(position_opts), to: AthenaCapture.PTZCameraCapture, as: :position_camera
  defdelegate get_ptz_position(), to: AthenaCapture.PTZCameraCapture, as: :get_last_position

  # Event querying
  defdelegate get_events(opts \\ []), to: AthenaCapture.EventStore
  defdelegate get_event_stats(), to: AthenaCapture.EventStore, as: :get_stats

  @doc """
  Convenience function for quick PTZ capture with common positions.
  
  ## Examples
  
      # Capture with camera looking straight ahead
      AthenaCapture.quick_ptz_capture(:center)
      
      # Capture with camera panned left
      AthenaCapture.quick_ptz_capture(:left)
      
      # Custom position
      AthenaCapture.quick_ptz_capture(%{pan: "middle", tilt: "up", zoom: 2})
  """
  def quick_ptz_capture(position_preset, opts \\ [])
  
  def quick_ptz_capture(:center, opts), do: capture_ptz_with_position(%{pan: "middle"}, opts)
  def quick_ptz_capture(:left, opts), do: capture_ptz_with_position(%{pan: "left"}, opts)
  def quick_ptz_capture(:right, opts), do: capture_ptz_with_position(%{pan: "right"}, opts)
  def quick_ptz_capture(:up, opts), do: capture_ptz_with_position(%{pan: "middle", tilt: "up"}, opts)
  def quick_ptz_capture(:down, opts), do: capture_ptz_with_position(%{pan: "middle", tilt: "down"}, opts)
  def quick_ptz_capture(position_map, opts) when is_map(position_map), do: capture_ptz_with_position(position_map, opts)
end
