defmodule AshChatWeb.Integration.DebugTest do
  use AshChatWeb.ConnCase
  import Phoenix.LiveViewTest
  
  @tag :integration
  test "debug message flow", %{conn: conn} do
    # Load the chat interface
    {:ok, view, html} = live(conn, "/chat")
    
    IO.puts("\nInitial HTML:")
    IO.puts(html)
    IO.puts("\n" <> String.duplicate("=", 80) <> "\n")
    
    # Send a message
    view
    |> form("#message-form", message: %{content: "Hi"})
    |> render_submit()
    
    # Wait a moment
    Process.sleep(1000)
    
    # Check what happened
    html = render(view)
    IO.puts("After submit HTML:")
    IO.puts(html)
  end
end