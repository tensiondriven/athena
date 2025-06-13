defmodule AshChat.Domain do
  use Ash.Domain

  resources do
    resource AshChat.Resources.Room
    resource AshChat.Resources.Message
    resource AshChat.Resources.Event
    resource AshChat.Resources.EventSource
    resource AshChat.Resources.Profile
    resource AshChat.Resources.SystemPrompt
    resource AshChat.Resources.AgentCard
    resource AshChat.Resources.User
    resource AshChat.Resources.RoomMembership
    resource AshChat.Resources.AgentMembership
    resource AshChat.Resources.Character
    resource AshChat.Resources.PromptTemplate
  end
end