defmodule AshChat.AI.ClaudeOneshotModel do
  @moduledoc """
  Claude OneShot CLI model adapter for LangChain compatibility
  """
  
  defstruct [:model, :temperature, :max_tokens]
  
  @type t :: %__MODULE__{
    model: String.t(),
    temperature: float(),
    max_tokens: integer()
  }
  
  def new!(opts) do
    %__MODULE__{
      model: opts[:model] || "claude-3-5-sonnet-20241022",
      temperature: opts[:temperature] || 0.7,
      max_tokens: opts[:max_tokens] || 2048
    }
  end
  
  # Implement LangChain ChatModel protocol methods as needed
  def call(%__MODULE__{} = model, messages, opts \\ []) do
    # Convert LangChain messages to text prompt
    prompt = format_messages_for_cli(messages)
    
    # Execute Claude CLI
    case execute_claude_cli(prompt, model, opts) do
      {:ok, response} ->
        {:ok, %LangChain.Message{role: :assistant, content: response}}
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  defp format_messages_for_cli(messages) do
    messages
    |> Enum.map(fn msg ->
      case msg.role do
        :system -> "System: #{msg.content}"
        :user -> "Human: #{msg.content}"
        :assistant -> "Assistant: #{msg.content}"
        _ -> "#{msg.role}: #{msg.content}"
      end
    end)
    |> Enum.join("\n\n")
  end
  
  defp execute_claude_cli(prompt, model, _opts) do
    # Generate unique temporary files
    input_file = "/tmp/claude_input_#{System.unique_integer([:positive])}.txt"
    output_file = "/tmp/claude_output_#{System.unique_integer([:positive])}.txt"
    
    try do
      # Write prompt to temporary file
      File.write!(input_file, prompt)
      
      # Build CLI command
      cmd_args = [
        "--model", model.model,
        "--temperature", Float.to_string(model.temperature),
        "--max-tokens", Integer.to_string(model.max_tokens),
        "--input", input_file,
        "--output", output_file
      ]
      
      # Execute Claude CLI
      case System.cmd("claude-code", cmd_args, stderr_to_stdout: true) do
        {_output, 0} ->
          # Read response from output file
          case File.read(output_file) do
            {:ok, response} -> 
              cleaned_response = String.trim(response)
              
              # Generate mini event for success
              AshChat.AI.EventGenerator.claude_oneshot_success(
                String.length(cleaned_response),
                %{model: model.model, prompt_length: String.length(prompt)}
              )
              
              {:ok, cleaned_response}
            {:error, _} -> {:error, "Failed to read Claude CLI output"}
          end
          
        {error_output, exit_code} ->
          require Logger
          Logger.error("Claude CLI failed with exit code #{exit_code}: #{error_output}")
          
          # Generate mini event for failure
          AshChat.AI.EventGenerator.claude_oneshot_failure(
            exit_code, 
            error_output,
            %{model: model.model, prompt_length: String.length(prompt)}
          )
          
          {:error, "Claude CLI execution failed: #{error_output}"}
      end
    rescue
      error ->
        require Logger
        Logger.error("Exception in Claude CLI execution: #{inspect(error)}")
        {:error, "Claude CLI execution error: #{Exception.message(error)}"}
    after
      # Clean up temporary files
      File.rm(input_file)
      File.rm(output_file)
    end
  end
end