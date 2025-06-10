defmodule AshChat.Resources.Message do
  use Ash.Resource,
    domain: AshChat.Domain,
    data_layer: Ash.DataLayer.Ets

  resource do
    description "A message in a chat conversation"
  end

  # TODO: Add AshAI vectorization when vector store is configured
  # ash_ai do
  #   vectorize text: :content,
  #            on: [:create, :update],
  #            store: AshChat.VectorStore
  # end

  attributes do
    uuid_primary_key :id
    attribute :content, :string, allow_nil?: false
    attribute :role, :atom, constraints: [one_of: [:user, :assistant, :system]], default: :user
    attribute :message_type, :atom, constraints: [one_of: [:text, :image, :multimodal]], default: :text
    attribute :image_url, :string
    attribute :image_data, :binary
    attribute :metadata, :map, default: %{}
    attribute :profile_id, :uuid  # Which profile generated this message (for assistant messages)
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :room, AshChat.Resources.Room
    belongs_to :profile, AshChat.Resources.Profile do
      source_attribute :profile_id
      destination_attribute :id
    end
  end

  actions do
    defaults [:create, :read, :update, :destroy]

    read :for_room do
      argument :room_id, :uuid, allow_nil?: false
      filter expr(room_id == ^arg(:room_id))
    end

    read :semantic_search do
      argument :query, :string, allow_nil?: false
      argument :limit, :integer, default: 10
      argument :threshold, :float, default: 0.8
      
      prepare fn query, _context ->
        # This will be handled by AshAI's semantic search
        query
      end
    end

    create :create_text_message do
      argument :room_id, :uuid, allow_nil?: false
      argument :content, :string, allow_nil?: false
      argument :role, :atom, default: :user

      change set_attribute(:room_id, arg(:room_id))
      change set_attribute(:content, arg(:content))
      change set_attribute(:role, arg(:role))
      change set_attribute(:message_type, :text)
    end

    create :create_image_message do
      argument :room_id, :uuid, allow_nil?: false
      argument :content, :string, default: ""
      argument :image_url, :string
      argument :image_data, :binary
      argument :role, :atom, default: :user

      change set_attribute(:room_id, arg(:room_id))
      change set_attribute(:content, arg(:content))
      change set_attribute(:role, arg(:role))
      change set_attribute(:message_type, :image)
      change set_attribute(:image_url, arg(:image_url))
      change set_attribute(:image_data, arg(:image_data))
    end
  end

  code_interface do
    domain AshChat.Domain
    define :create
    define :read
    define :create_text_message
    define :create_image_message
    define :for_room
    define :semantic_search
  end
end