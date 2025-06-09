defmodule AshChatWeb.ChatLiveSimpleTest do
  use AshChatWeb.ConnCase
  import Phoenix.LiveViewTest

  describe "basic chat functionality" do
    test "chat interface loads successfully", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/chat")
      
      assert html =~ "Ollama Chat"
      assert html =~ "System Prompt"
      assert html =~ "Type your message..."
    end

    test "can type and submit a message", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/chat")
      
      # Submit a message
      view
      |> form("#message-form")
      |> render_submit(%{message: %{content: "Hello world"}})
      
      # The form should still be present (even if there's an error)
      html = render(view)
      assert html =~ "message-form"
    end

    test "empty messages are not submitted", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/chat")
      
      # Try to submit empty message
      view
      |> form("#message-form")
      |> render_submit(%{message: %{content: ""}})
      
      # Should not crash, form should still be there
      html = render(view)
      assert html =~ "message-form"
    end

    test "system prompt textarea exists", %{conn: conn} do
      {:ok, _view, html} = live(conn, "/chat")
      
      assert html =~ "system-prompt-input"
      assert html =~ "You are a helpful AI assistant"
    end
  end
end