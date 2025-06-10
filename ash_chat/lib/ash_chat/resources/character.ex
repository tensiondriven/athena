defmodule AshChat.Resources.Character do
  @moduledoc """
  Character represents an AI agent based on SillyTavern character card format.
  
  Stores the complete SillyTavern JSON blob for compatibility while extracting
  common fields for UI/search. Separates character data from model-specific
  prompt formatting (handled by PromptTemplate).
  """
  
  use Ash.Resource,
    domain: AshChat.Domain,
    data_layer: Ash.DataLayer.Ets

  # Stubbed AshAI integration (ready for Phase 3)
  # ash_ai do
  #   vectorize text: [:name, :description, "sillytavern_data.personality"],
  #            strategy: :ash_oban,
  #            store: AshChat.VectorStore
  # end

  attributes do
    uuid_primary_key :id

    # SillyTavern compatibility - store the complete character card
    attribute :sillytavern_data, :map do
      allow_nil? false
      description "Complete SillyTavern character card JSON"
    end

    # Extracted fields for UI/search (derived from sillytavern_data)
    attribute :name, :string do
      allow_nil? false
      description "Character name (extracted from sillytavern_data.name)"
    end
    
    attribute :description, :string do
      description "Brief character description (extracted from sillytavern_data.description)"
    end

    attribute :personality, :string do
      description "Character personality (extracted from sillytavern_data.personality)"
    end

    attribute :first_message, :string do
      description "Character greeting (extracted from sillytavern_data.first_mes)"
    end

    attribute :scenario, :string do
      description "Character scenario (extracted from sillytavern_data.scenario)"
    end

    # Athena-specific metadata
    attribute :is_active, :boolean do
      default true
      description "Whether this character is available for use"
    end

    attribute :tags, {:array, :string} do
      default []
      description "Custom tags for organization and search"
    end
    
    timestamps()
  end

  relationships do
    belongs_to :personality, AshChat.Resources.Personality do
      description "Optional personality template this character uses"
    end
    
    has_many :messages, AshChat.Resources.Message do
      description "Messages sent by this character"
    end
  end

  actions do
    defaults [:read, :destroy]
    
    create :create do
      accept [:sillytavern_data, :name, :description, :personality, :first_message, 
              :scenario, :is_active, :tags, :personality_id]
      
      change fn changeset, _context ->
        # Auto-extract fields from sillytavern_data if not provided
        if changeset.arguments[:sillytavern_data] && !changeset.arguments[:name] do
          data = changeset.arguments[:sillytavern_data]
          changeset
          |> Ash.Changeset.change_attribute(:name, data["name"])
          |> Ash.Changeset.change_attribute(:description, data["description"]) 
          |> Ash.Changeset.change_attribute(:personality, data["personality"])
          |> Ash.Changeset.change_attribute(:first_message, data["first_mes"])
          |> Ash.Changeset.change_attribute(:scenario, data["scenario"])
        else
          changeset
        end
      end
    end
    
    update :update do
      accept [:sillytavern_data, :name, :description, :personality, :first_message,
              :scenario, :is_active, :tags, :personality_id]
    end
    
    read :active do
      filter expr(is_active == true)
    end
    
    read :by_name do
      argument :name, :string, allow_nil?: false
      filter expr(name == ^arg(:name))
    end

    read :by_tags do
      argument :tags, {:array, :string}, allow_nil?: false
      filter expr(fragment("? && ?", tags, ^arg(:tags)))
    end
  end

  calculations do
    calculate :sillytavern_export, :map, expr("Export SillyTavern compatible JSON") do
      calculation fn records, _context ->
        Enum.map(records, &(&1.sillytavern_data))
      end
    end
  end

  # Stubbed semantic search (ready for AshAI)
  read :semantic_search do
    argument :query, :string, allow_nil?: false
    argument :limit, :integer, default: 10
    
    # This will be handled by AshAI's semantic search when enabled
    # For now, simple text search
    filter expr(ilike(name, ^("%#{arg(:query)}%")) or ilike(description, ^("%#{arg(:query)}%")))
    limit expr(^arg(:limit))
  end

  code_interface do
    define_for AshChat.Domain
    define :create
    define :read
    define :update
    define :destroy
    define :active
    define :by_name, args: [:name]
    define :by_tags, args: [:tags]
    define :semantic_search, args: [:query]
  end

  # SillyTavern import/export helpers
  def from_sillytavern_json(json_data) when is_map(json_data) do
    create(%{
      sillytavern_data: json_data,
      name: json_data["name"],
      description: json_data["description"],
      personality: json_data["personality"],
      first_message: json_data["first_mes"],
      scenario: json_data["scenario"]
    })
  end

  def to_sillytavern_json(%__MODULE__{} = character) do
    character.sillytavern_data
  end

  # JSON-LD export (for future Neo4j integration)
  def to_json_ld(%__MODULE__{} = character) do
    %{
      "@context" => %{
        "schema" => "https://schema.org/",
        "athena" => "https://athena.local/vocab/"
      },
      "@type" => ["schema:Person", "athena:Character"],
      "@id" => "character_#{character.id}",
      "schema:name" => character.name,
      "schema:description" => character.description,
      "athena:personality" => character.personality,
      "athena:scenario" => character.scenario,
      "athena:sillyTavernData" => character.sillytavern_data
    }
  end
end