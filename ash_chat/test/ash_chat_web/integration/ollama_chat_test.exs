defmodule AshChatWeb.Integration.OllamaChatTest do
  use AshChatWeb.ConnCase
  import Phoenix.LiveViewTest
  
  @ollama_timeout 30_000  # 30 seconds for Ollama to respond
  @test_message "What is 2+2? Reply with just the number."
  @system_prompt "You are a helpful assistant. Keep responses very brief."

  describe "Ollama integration" do
    @tag :integration
    @tag timeout: 60_000  # 1 minute total timeout
    test "sends message to Ollama and receives response", %{conn: conn} do
      # Load the chat interface
      {:ok, view, html} = live(conn, "/chat")
      
      assert html =~ "Ollama Chat"
      IO.puts("\n✓ Chat interface loaded")
      
      # Set a simple system prompt by simulating the blur event (like the browser would)
      render_blur(view, "update_system_prompt", %{value: @system_prompt})
      
      IO.puts("✓ System prompt set: #{@system_prompt}")
      
      # Send a test message
      view
      |> form("#message-form", message: %{content: @test_message})
      |> render_submit()
      
      IO.puts("✓ Message sent: #{@test_message}")
      IO.puts("⏳ Waiting for Ollama response...")
      
      # Wait for the response with polling
      result = wait_for_ollama_response(view, @ollama_timeout)
      
      case result do
        {:ok, response} ->
          IO.puts("✓ Ollama responded: #{response}")
          assert response =~ "4" or response =~ "four", 
            "Expected response to contain '4' or 'four', got: #{response}"
          IO.puts("\n✅ Integration test passed!")
          
        {:error, reason} ->
          flunk("Failed to get Ollama response: #{reason}")
      end
    end
    
    @tag :integration
    test "handles Ollama connection errors gracefully", %{conn: conn} do
      # Temporarily mock the Ollama URL to simulate connection failure
      original_config = Application.get_env(:langchain, :ollama_url)
      Application.put_env(:langchain, :ollama_url, "http://invalid-host:11434/")
      
      try do
        {:ok, view, _html} = live(conn, "/chat")
        
        # Send a message that should fail
        view
        |> form("#message-form", message: %{content: "This should fail"})
        |> render_submit()
        
        # Wait a bit for the error to appear
        Process.sleep(1000)
        
        # Check for error flash
        html = render(view)
        assert html =~ "Error" or html =~ "error" or html =~ "failed",
          "Expected error message in response"
          
        IO.puts("✓ Error handling verified")
      after
        # Restore original config
        Application.put_env(:langchain, :ollama_url, original_config)
      end
    end
  end
  
  # Helper function to wait for Ollama response
  defp wait_for_ollama_response(view, timeout) do
    start_time = System.monotonic_time(:millisecond)
    
    poll_for_response(view, start_time, timeout)
  end
  
  defp poll_for_response(view, start_time, timeout) do
    elapsed = System.monotonic_time(:millisecond) - start_time
    
    if elapsed > timeout do
      {:error, "Timeout waiting for Ollama response after #{timeout}ms"}
    else
      html = render(view)
      
      # Look for assistant response in the chat
      cond do
        # Still processing - look for the thinking indicator
        html =~ "AI is thinking..." ->
          Process.sleep(500)
          poll_for_response(view, start_time, timeout)
          
        # Check for actual error messages (not just the presence of error styling)
        html =~ "Error" and html =~ "bg-rose-50" ->
          # Debug: print the HTML to see what's happening
          IO.puts("\n🔍 Found error message in HTML:")
          IO.puts(String.slice(html, 0, 1000) <> "...")
          {:error, "Error occurred during processing"}
          
        # Look for a gray message box (assistant response) that contains a number
        html =~ ~r/bg-gray-100.*?text-gray-900.*?>.*?(\d|four)/s ->
          IO.puts("\n✅ Found assistant response pattern in HTML")
          # Extract the assistant's response
          case extract_assistant_response(html) do
            nil -> 
              IO.puts("⏳ Found assistant message but couldn't extract content")
              Process.sleep(500)
              poll_for_response(view, start_time, timeout)
            response -> 
              IO.puts("📝 Extracted response: #{response}")
              {:ok, response}
          end
          
        true ->
          # Debug: print the HTML to see what we're getting
          if rem(elapsed, 2000) == 0 do  # Every 2 seconds
            IO.puts("\n⏳ Still waiting (#{elapsed}ms)... Looking for assistant response")
            # Look for any message divs
            messages = Regex.scan(~r/<div class="[^"]*">[^<]*<div class="[^"]*(?:blue-500|gray-100)[^"]*">/s, html)
            IO.puts("Found #{length(messages)} message(s) in HTML")
            
            # Print the last part of the HTML where messages would be
            if String.contains?(html, "Messages Area") do
              [_before, messages_area] = String.split(html, "Messages Area", parts: 2)
              IO.puts("Messages area content:")
              IO.puts(String.slice(messages_area, 0, 1500) <> "...")
            end
          end
          Process.sleep(500)
          poll_for_response(view, start_time, timeout)
      end
    end
  end
  
  defp extract_assistant_response(html) do
    # Extract content from gray message boxes (assistant responses)
    # Looking for the pattern of assistant message styling
    case Regex.run(~r/bg-gray-100\s+text-gray-900.*?<p[^>]*class="text-sm[^"]*">([^<]+)<\/p>/s, html) do
      [_, content] -> String.trim(content)
      _ -> nil
    end
  end
end