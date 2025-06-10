defmodule AshChat.Domain do
  use Ash.Domain

  resources do
    resource AshChat.Resources.Room
    resource AshChat.Resources.Message
    resource AshChat.Resources.Event
    resource AshChat.Resources.EventSource
    resource AshChat.Resources.Profile
  end
end