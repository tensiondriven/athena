defmodule AshChat.Resources.EventSource do
  use Ash.Resource,
    domain: AshChat.Domain,
    data_layer: Ash.DataLayer.Ets

  resource do
    description "A source that generates events (collector, camera, sensor, etc.)"
  end

  attributes do
    uuid_primary_key :id
    attribute :name, :string, allow_nil?: false
    attribute :source_type, :atom, 
      constraints: [one_of: [:collector, :camera, :sensor, :file_monitor, :chat_log, :browser]], 
      allow_nil?: false
    attribute :description, :string
    attribute :config, :map, default: %{}
    attribute :active, :boolean, default: true
    attribute :last_event_at, :utc_datetime_usec
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    has_many :events, AshChat.Resources.Event
  end

  actions do
    defaults [:read, :update, :destroy]

    create :create do
      accept [:name, :source_type, :description, :config, :active]
    end

    read :active do
      filter expr(active == true)
    end

    read :by_type do
      argument :source_type, :atom, allow_nil?: false
      filter expr(source_type == ^arg(:source_type))
    end

    update :update_last_event do
      accept []
      change set_attribute(:last_event_at, &DateTime.utc_now/0)
    end
  end

  code_interface do
    domain AshChat.Domain
    define :create
    define :read
    define :active
    define :by_type
    define :update
    define :update_last_event
  end
end