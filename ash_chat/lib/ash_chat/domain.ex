defmodule AshChat.Domain do
  use Ash.Domain

  resources do
    resource AshChat.Resources.Chat
    resource AshChat.Resources.Message
    resource AshChat.Resources.Event
    resource AshChat.Resources.EventSource
  end
end