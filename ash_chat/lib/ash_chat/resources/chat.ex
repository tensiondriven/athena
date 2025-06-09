defmodule AshChat.Resources.Chat do
  use Ash.Resource,
    domain: AshChat.Domain,
    data_layer: Ash.DataLayer.Ets

  resource do
    description "A chat conversation"
  end

  attributes do
    uuid_primary_key :id
    attribute :title, :string, default: "New Chat"
    attribute :active, :boolean, default: true
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :messages, AshChat.Resources.Message
  end

  actions do
    defaults [:read, :update, :destroy]

    create :create do
      accept [:title]
    end

    read :active do
      filter expr(active == true)
    end
  end

  code_interface do
    domain AshChat.Domain
    define :create
    define :read
    define :list_active, action: :active
    define :update
  end
end