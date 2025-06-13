#!/usr/bin/env elixir

# Test script for Ollama model loading status detection
# Run with: elixir test_ollama_status_detection.exs

Mix.install([
  {:httpoison, "~> 2.0"},
  {:jason, "~> 1.4"}
])

defmodule OllamaStatusTest do
  @ollama_host System.get_env("OLLAMA_HOST", "http://localhost:11434")
  
  def run_tests do
    IO.puts("\n=== Ollama Model Loading Status Detection Tests ===\n")
    
    # Test 1: Check if Ollama is running
    IO.puts("1. Checking Ollama availability...")
    case check_ollama_running() do
      :ok -> 
        IO.puts("   ✓ Ollama is running")
        
        # Test 2: List available models
        IO.puts("\n2. Listing available models...")
        list_models()
        
        # Test 3: Test model loading detection
        IO.puts("\n3. Testing model loading detection...")
        test_model_loading("llama3.2:1b")
        
        # Test 4: Demonstrate loading state changes
        IO.puts("\n4. Demonstrating loading state changes...")
        demonstrate_loading_states("llama3.2:1b")
        
      :error ->
        IO.puts("   ✗ Ollama is not running!")
        IO.puts("   Please start Ollama with: ollama serve")
    end
  end
  
  defp check_ollama_running do
    case HTTPoison.get(@ollama_host) do
      {:ok, %{status_code: 200}} -> :ok
      _ -> :error
    end
  end
  
  defp list_models do
    case HTTPoison.get("#{@ollama_host}/api/tags") do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"models" => models}} ->
            Enum.each(models, fn model ->
              size_mb = Float.round(model["size"] / 1_000_000, 2)
              IO.puts("   - #{model["name"]} (#{size_mb} MB)")
            end)
          _ ->
            IO.puts("   Failed to parse models")
        end
      _ ->
        IO.puts("   Failed to fetch models")
    end
  end
  
  defp test_model_loading(model_name) do
    IO.puts("   Testing with model: #{model_name}")
    
    # First request - model might need loading
    IO.puts("\n   First request (model might need loading):")
    {load_time1, total_time1} = make_test_request(model_name, "1s")
    IO.puts("   - Load duration: #{load_time1} ms")
    IO.puts("   - Total request time: #{total_time1} ms")
    IO.puts("   - Model was #{if load_time1 > 0, do: "LOADED", else: "already in memory"}")
    
    # Wait a moment
    Process.sleep(100)
    
    # Second request - model should be in memory
    IO.puts("\n   Second request (model should be in memory):")
    {load_time2, total_time2} = make_test_request(model_name, "5m")
    IO.puts("   - Load duration: #{load_time2} ms")
    IO.puts("   - Total request time: #{total_time2} ms")
    IO.puts("   - Model was #{if load_time2 > 0, do: "LOADED", else: "already in memory"}")
  end
  
  defp make_test_request(model_name, keep_alive) do
    request_body = %{
      model: model_name,
      prompt: "Hi",
      stream: false,
      keep_alive: keep_alive
    }
    
    start_time = System.monotonic_time(:millisecond)
    
    case HTTPoison.post(
      "#{@ollama_host}/api/generate",
      Jason.encode!(request_body),
      [{"Content-Type", "application/json"}],
      recv_timeout: 60_000
    ) do
      {:ok, %{status_code: 200, body: body}} ->
        end_time = System.monotonic_time(:millisecond)
        total_time = end_time - start_time
        
        case Jason.decode(body) do
          {:ok, response} ->
            load_duration = response["load_duration"] || 0
            load_duration_ms = Float.round(load_duration / 1_000_000, 2)
            {load_duration_ms, total_time}
          _ ->
            {0, total_time}
        end
      _ ->
        {0, 0}
    end
  end
  
  defp demonstrate_loading_states(model_name) do
    IO.puts("   This demonstrates how to detect different loading states:")
    IO.puts("")
    IO.puts("   Key findings from API research:")
    IO.puts("   - load_duration > 0: Model was loaded from disk into VRAM/RAM")
    IO.puts("   - load_duration = 0: Model was already in memory")
    IO.puts("   - Use keep_alive parameter to control memory residence time")
    IO.puts("   - Monitor /api/pull for download progress")
    IO.puts("")
    IO.puts("   Practical approach:")
    IO.puts("   1. Check model availability with /api/tags")
    IO.puts("   2. Make a test request with short keep_alive")
    IO.puts("   3. Check load_duration to determine if loading occurred")
    IO.puts("   4. For production, preload with longer keep_alive")
  end
end

# Run the tests
OllamaStatusTest.run_tests()