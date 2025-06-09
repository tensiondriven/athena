defmodule AshChatWeb.ChatLiveIntegrationTest do
  use AshChatWeb.ConnCase
  import Phoenix.LiveViewTest
  
  # This test file focuses on integration testing of the chat functionality
  # including the actual message sending flow

  setup do
    # Clean up any existing data
    :ok
  end

  describe "send_message integration" do
    test "complete message send flow without LLM", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/chat")
      
      # Get the chat ID that was created
      chat_id = view.assigns.chat.id
      assert chat_id
      
      # Verify initial state
      assert view.assigns.messages == []
      assert view.assigns.processing == false
      
      # Send a message through the form
      view
      |> form("#message-form", message: %{content: "Hello, test!"})
      |> render_submit()
      
      # The send_message event should have been handled
      # Check that a message was created
      messages = AshChat.Resources.Message.for_chat!(chat_id)
      assert length(messages) >= 1
      
      # Find the user message
      user_message = Enum.find(messages, & &1.role == :user)
      assert user_message
      assert user_message.content == "Hello, test!"
      assert user_message.message_type == :text
      assert user_message.chat_id == chat_id
    end

    test "send_message creates correct message record", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/chat")
      chat_id = view.assigns.chat.id
      
      # Directly trigger the send_message event
      view
      |> element("#message-form")
      |> render_submit(%{message: %{content: "Direct event test"}})
      
      # Verify the message was created correctly
      messages = AshChat.Resources.Message.for_chat!(chat_id)
      message = List.first(messages)
      
      assert message.content == "Direct event test"
      assert message.role == :user
      assert message.message_type == :text
      assert message.chat_id == chat_id
      refute message.image_url
      refute message.image_data
    end

    test "empty message doesn't create record", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/chat")
      chat_id = view.assigns.chat.id
      
      # Try to send empty message
      view
      |> form("#message-form", message: %{content: ""})
      |> render_submit()
      
      # No message should be created
      messages = AshChat.Resources.Message.for_chat!(chat_id)
      assert messages == []
    end

    test "system prompt is included in config", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/chat")
      
      # Set system prompt
      view
      |> element("#system-prompt-input")
      |> render_blur(%{value: "You are a pirate. Always respond like a pirate."})
      
      # The system prompt should be in the assigns
      assert view.assigns.system_prompt == "You are a pirate. Always respond like a pirate."
    end

    test "processing state during message send", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/chat")
      
      # Before sending
      assert view.assigns.processing == false
      
      # Send message
      view
      |> form("#message-form", message: %{content: "Test processing state"})
      |> render_submit()
      
      # After completion, processing should be false again
      # (In a real scenario with async LLM calls, you'd test the intermediate state)
      assert view.assigns.processing == false
    end

    test "error handling when ChatAgent fails", %{conn: conn} do
      # This test would require mocking ChatAgent.process_message_with_system_prompt
      # to return an error. Here's the structure:
      
      {:ok, view, _html} = live(conn, "/chat")
      
      # In a real test with Mox:
      # expect(ChatAgentMock, :process_message_with_system_prompt, fn _, _, _ ->
      #   {:error, "LLM connection failed"}
      # end)
      
      # Send message that will fail
      view
      |> form("#message-form", message: %{content: "This will fail"})
      |> render_submit()
      
      # Check that an error flash was set
      # assert render(view) =~ "alert-error"
    end
  end

  describe "message updates" do
    test "view updates when new messages are added", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/chat")
      chat_id = view.assigns.chat.id
      
      # Create a message outside of the view
      AshChat.Resources.Message.create_text_message!(%{
        chat_id: chat_id,
        content: "External message",
        role: :assistant
      })
      
      # Send update message to the view
      send(view.pid, :update_messages)
      
      # The view should now show the message
      html = render(view)
      assert html =~ "External message"
      assert html =~ "assistant:"
    end
  end
end