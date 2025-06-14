defmodule AshChat.PngMetadata do
  @moduledoc """
  Extract character card data from PNG metadata.
  
  SillyTavern stores character data in PNG tEXt chunks with key "chara".
  The data is base64-encoded JSON.
  """
  
  require Logger
  
  @doc """
  Extract character data from a PNG file.
  
  Returns {:ok, character_data} or {:error, reason}
  """
  def extract_character_data(png_binary) when is_binary(png_binary) do
    with :ok <- validate_png_signature(png_binary),
         {:ok, chunks} <- parse_chunks(png_binary),
         {:ok, chara_data} <- find_chara_chunk(chunks),
         {:ok, json_data} <- decode_chara_data(chara_data) do
      {:ok, json_data}
    end
  end
  
  defp validate_png_signature(<<137, 80, 78, 71, 13, 10, 26, 10, _rest::binary>>) do
    :ok
  end
  
  defp validate_png_signature(_) do
    {:error, "Invalid PNG signature"}
  end
  
  defp parse_chunks(<<_signature::binary-size(8), rest::binary>>) do
    parse_chunks_recursive(rest, [])
  end
  
  defp parse_chunks_recursive(<<>>, chunks), do: {:ok, Enum.reverse(chunks)}
  
  defp parse_chunks_recursive(<<length::big-32, type::binary-size(4), rest::binary>>, chunks) do
    if byte_size(rest) >= length + 4 do
      <<data::binary-size(length), _crc::big-32, remaining::binary>> = rest
      chunk = {type, data}
      
      # Stop at IEND chunk
      if type == "IEND" do
        {:ok, Enum.reverse([chunk | chunks])}
      else
        parse_chunks_recursive(remaining, [chunk | chunks])
      end
    else
      {:error, "Invalid chunk structure - insufficient data"}
    end
  end
  
  defp parse_chunks_recursive(_, _), do: {:error, "Invalid PNG structure"}
  
  defp find_chara_chunk(chunks) do
    # Look for tEXt chunk with "chara" keyword
    case Enum.find(chunks, fn 
      {"tEXt", data} -> String.starts_with?(data, "chara\0")
      _ -> false
    end) do
      {"tEXt", data} ->
        # Remove "chara\0" prefix
        <<_prefix::binary-size(6), chara_data::binary>> = data
        {:ok, chara_data}
        
      nil ->
        {:error, "No character data found in PNG"}
    end
  end
  
  defp decode_chara_data(base64_data) do
    case Base.decode64(base64_data) do
      {:ok, json_string} ->
        Jason.decode(json_string)
        
      :error ->
        {:error, "Invalid base64 encoding"}
    end
  end
  
  @doc """
  Create a PNG with embedded character data.
  
  Takes an existing PNG and character data, returns a new PNG with the data embedded.
  """
  def embed_character_data(png_binary, character_data) when is_binary(png_binary) and is_map(character_data) do
    with :ok <- validate_png_signature(png_binary),
         {:ok, json_string} <- Jason.encode(character_data),
         base64_data <- Base.encode64(json_string) do
      
      # Create tEXt chunk with "chara" keyword
      text_data = "chara\0" <> base64_data
      text_chunk = create_text_chunk(text_data)
      
      # Insert after IHDR chunk (required to be first)
      new_png = insert_chunk_after_ihdr(png_binary, text_chunk)
      {:ok, new_png}
    end
  end
  
  defp create_text_chunk(data) do
    length = byte_size(data)
    type = "tEXt"
    crc = :erlang.crc32(type <> data)
    
    <<length::big-32>> <> type <> data <> <<crc::big-32>>
  end
  
  defp insert_chunk_after_ihdr(png_binary, new_chunk) do
    <<signature::binary-size(8), rest::binary>> = png_binary
    
    # IHDR is always first chunk, with fixed size
    <<ihdr_length::big-32, "IHDR", ihdr_data::binary-size(13), ihdr_crc::big-32, remaining::binary>> = rest
    
    # Reconstruct PNG with new chunk after IHDR
    signature <> 
    <<ihdr_length::big-32>> <> "IHDR" <> ihdr_data <> <<ihdr_crc::big-32>> <>
    new_chunk <>
    remaining
  end
end