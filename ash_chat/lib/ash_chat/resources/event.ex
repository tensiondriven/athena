defmodule AshChat.Resources.Event do
  use Ash.Resource,
    domain: AshChat.Domain,
    data_layer: Ash.DataLayer.Ets

  resource do
    description "An event captured by the Athena collector system"
  end

  attributes do
    uuid_primary_key :id
    attribute :timestamp, :utc_datetime_usec, allow_nil?: false
    attribute :event_type, :string, allow_nil?: false
    attribute :source_id, :string, allow_nil?: false
    attribute :source_path, :string
    attribute :content, :string
    attribute :confidence, :float
    attribute :description, :string
    attribute :metadata, :map, default: %{}
    attribute :validation_errors, :string
    create_timestamp :created_at
    update_timestamp :updated_at
  end

  relationships do
    belongs_to :event_source, AshChat.Resources.EventSource
  end

  actions do
    defaults [:read, :update, :destroy]

    create :create do
      accept [:timestamp, :event_type, :source_id, :source_path, :content, :confidence, :description, :metadata, :validation_errors]
    end

    create :create_from_collector do
      argument :timestamp, :string, allow_nil?: false
      argument :event_type, :string, allow_nil?: false
      argument :source_id, :string, allow_nil?: false
      argument :source_path, :string
      argument :content, :string
      argument :confidence, :float
      argument :description, :string
      argument :metadata, :map, default: %{}
      argument :validation_errors, :string

      change fn changeset, _context ->
        # Parse timestamp from ISO string to DateTime
        timestamp_str = Ash.Changeset.get_argument(changeset, :timestamp)
        
        case DateTime.from_iso8601(timestamp_str) do
          {:ok, datetime, _offset} ->
            changeset
            |> Ash.Changeset.change_attribute(:timestamp, datetime)
            |> Ash.Changeset.change_attribute(:event_type, Ash.Changeset.get_argument(changeset, :event_type))
            |> Ash.Changeset.change_attribute(:source_id, Ash.Changeset.get_argument(changeset, :source_id))
            |> Ash.Changeset.change_attribute(:source_path, Ash.Changeset.get_argument(changeset, :source_path))
            |> Ash.Changeset.change_attribute(:content, Ash.Changeset.get_argument(changeset, :content))
            |> Ash.Changeset.change_attribute(:confidence, Ash.Changeset.get_argument(changeset, :confidence))
            |> Ash.Changeset.change_attribute(:description, Ash.Changeset.get_argument(changeset, :description))
            |> Ash.Changeset.change_attribute(:metadata, Ash.Changeset.get_argument(changeset, :metadata))
            |> Ash.Changeset.change_attribute(:validation_errors, Ash.Changeset.get_argument(changeset, :validation_errors))
          
          {:error, _reason} ->
            Ash.Changeset.add_error(changeset, field: :timestamp, message: "Invalid timestamp format")
        end
      end
    end

    read :recent do
      argument :limit, :integer, default: 50
      
      prepare fn query, _context ->
        limit = Ash.Query.get_argument(query, :limit)
        query
        |> Ash.Query.sort(created_at: :desc)
        |> Ash.Query.limit(limit)
      end
    end

    read :by_event_type do
      argument :event_type, :string, allow_nil?: false
      argument :limit, :integer, default: 50
      
      filter expr(event_type == ^arg(:event_type))
      
      prepare fn query, _context ->
        limit = Ash.Query.get_argument(query, :limit)
        query
        |> Ash.Query.sort(created_at: :desc)
        |> Ash.Query.limit(limit)
      end
    end

    read :by_source do
      argument :source_id, :string, allow_nil?: false
      argument :limit, :integer, default: 50
      
      filter expr(source_id == ^arg(:source_id))
      
      prepare fn query, _context ->
        limit = Ash.Query.get_argument(query, :limit)
        query
        |> Ash.Query.sort(created_at: :desc)
        |> Ash.Query.limit(limit)
      end
    end
  end

  code_interface do
    domain AshChat.Domain
    define :create
    define :create_from_collector
    define :read
    define :recent
    define :by_event_type
    define :by_source
    define :update
  end
end