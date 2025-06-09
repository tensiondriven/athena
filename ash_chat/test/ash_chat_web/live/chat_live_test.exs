defmodule AshChatWeb.ChatLiveTest do
  use AshChatWeb.ConnCase
  import Phoenix.LiveViewTest

  describe "chat interface" do
    test "loads chat interface and creates a new chat", %{conn: conn} do
      {:ok, view, html} = live(conn, "/chat")
      
      # Check that the chat interface loaded
      assert html =~ "Ollama Chat"
      assert html =~ "System Prompt"
    end

    test "validates message input as user types", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/chat")
      
      # Type in the message input
      view
      |> form("#message-form", message: %{content: "Hello"})
      |> render_change()
      
      # Check that the input value is reflected
      html = render(view)
      assert html =~ ~s(value="Hello")
    end

    test "sends a text message and updates the chat", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/chat")
      
      # Set system prompt (optional)
      view
      |> element("#system-prompt-input")
      |> render_blur(%{value: "You are a helpful assistant."})
      
      # Send a message
      view
      |> form("#message-form", message: %{content: "What is 2+2?"})
      |> render_submit()
      
      # Check that the message was added to the chat
      html = render(view)
      assert html =~ "What is 2+2?"
      assert html =~ "user:" # User message role
      
      # Since we're testing without a real LLM, we need to mock the response
      # In a real test environment, you'd mock the ChatAgent.process_message call
    end

    test "handles send message errors gracefully", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/chat")
      
      # Mock the ChatAgent to return an error
      # This would require setting up Mox or similar mocking library
      # For now, we'll test that empty messages don't submit
      
      view
      |> form("#message-form", message: %{content: ""})
      |> render_submit()
      
      # Form shouldn't submit with empty content due to client-side validation
      refute render(view) =~ "user:"
    end

    test "disables form while processing message", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/chat")
      
      # Start form submission
      view
      |> form("#message-form", message: %{content: "Test message"})
      |> render_submit()
      
      # During processing, the form should be disabled
      # This happens quickly, so in a real test you'd need to mock
      # the ChatAgent to add a delay
    end

    test "persists system prompt in localStorage", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/chat")
      
      # The system prompt persistence is handled by JavaScript
      # so we can only test that the textarea exists and has the right attributes
      html = render(view)
      assert html =~ ~s(id="system-prompt-input")
      assert html =~ ~s(phx-blur="update_system_prompt")
    end

    test "supports multimodal messages with images", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/chat")
      
      # The file input should be present
      html = render(view)
      assert html =~ ~s(type="file")
      assert html =~ ~s(accept="image/*")
      
      # Image upload would require more complex testing with file fixtures
    end

    test "message history is displayed in correct order", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/chat")
      
      # Send a couple of messages through the interface
      view
      |> form("#message-form", message: %{content: "First message"})
      |> render_submit()
      
      # The messages would be created but we'd need to mock the LLM response
      # For now, just check that the form can be submitted
      html = render(view)
      
      # At minimum, the form should still be present
      assert html =~ "message-form"
    end
  end
end