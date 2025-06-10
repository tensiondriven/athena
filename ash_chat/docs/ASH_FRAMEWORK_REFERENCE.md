# Ash Framework 3.x Reference Guide

## Core Architecture Best Practices

### Resource Organization (Ash 3.x)
- **Domains**: Group related resources together for context boundaries
- **Resources**: Model data and behavior as declarative entities
- **Actions**: Define what can be done with resources (CRUD + custom)
- **Relationships**: Connect resources with belongs_to, has_many, etc.

### Data Layer Strategy
```elixir
# Development/Prototyping
data_layer: Ash.DataLayer.Ets  # In-memory, fast iteration

# Production 
data_layer: AshPostgres.DataLayer  # PostgreSQL with migrations
```

### Relationship Best Practices
```elixir
# In Ash 3.0, relationships are defined within domains
relationships do
  belongs_to :user, MyApp.User do
    # Clear relationship definition
    attribute_writable? true  # Allow setting user_id on create
  end
  
  has_many :messages, MyApp.Message do
    # Efficient loading patterns
    read_action :for_room  # Custom read action for performance
  end
end
```

## AshAI Integration Patterns

### Vectorization Strategy Selection

**:after_action (Development Only)**
```elixir
ash_ai do
  vectorize text: :content,
           on: [:create, :update],
           store: MyApp.VectorStore,
           strategy: :after_action  # Synchronous - SLOW in production
end
```

**:ash_oban (Production Recommended)**
```elixir
ash_ai do
  vectorize text: :content,
           on: [:create, :update], 
           store: MyApp.VectorStore,
           strategy: :ash_oban  # Async background processing
end
```

**:manual (Custom Control)**
```elixir
ash_ai do
  vectorize text: :content,
           strategy: :manual  # Manual trigger for embedding updates
end
```

### Embedding Performance Optimization
```elixir
ash_ai do
  vectorize text: [:content, :title],
           on: [:create, :update],
           # Only rebuild embeddings when these attributes change
           when_attributes: [:content, :title],
           store: MyApp.VectorStore
end
```

### Semantic Search Actions
```elixir
read :semantic_search do
  argument :query, :string, allow_nil?: false
  argument :limit, :integer, default: 10
  argument :threshold, :float, default: 0.8
  
  # AshAI handles the vector search implementation
  filter expr(semantic_similarity(content, ^arg(:query)) > ^arg(:threshold))
  sort [:semantic_similarity]
  limit expr(^arg(:limit))
end
```

## Resource Design Patterns

### Attribute Design
```elixir
attributes do
  uuid_primary_key :id
  
  # Required fields
  attribute :name, :string, allow_nil?: false
  
  # Arrays for multiple values
  attribute :tags, {:array, :string}, default: []
  
  # Maps for flexible structured data
  attribute :metadata, :map, default: %{}
  
  # Constrained values
  attribute :status, :atom, 
    constraints: [one_of: [:active, :inactive, :pending]]
    
  timestamps()
end
```

### Action Patterns
```elixir
actions do
  # Standard CRUD with customization
  defaults [:read, :destroy]
  
  create :create do
    accept [:name, :description, :tags]
    # Custom validation/logic here
  end
  
  update :update do
    accept [:name, :description, :tags] 
    # Don't expose all attributes
  end
  
  # Custom business logic actions
  read :active do
    filter expr(status == :active)
  end
  
  read :by_name do
    argument :name, :string, allow_nil?: false
    filter expr(name == ^arg(:name))
  end
end
```

### Code Interface Best Practices
```elixir
code_interface do
  define_for MyApp.Domain
  define :create
  define :read  
  define :update
  define :destroy
  define :active
  define :by_name, args: [:name]
end
```

## Tool Calling Integration

### Making Actions LLM-Callable
```elixir
# Any Ash action can become an LLM tool
action :create_task do
  argument :title, :string, allow_nil?: false
  argument :description, :string
  argument :priority, :atom, constraints: [one_of: [:low, :medium, :high]]
  
  # This action is automatically exposed as an LLM tool
  returns :struct
end
```

### MCP Server Generation
```bash
# Generate MCP server exposing Ash actions as tools
mix ash_ai.gen.mcp --name MyAppMCP --resources User,Task,Message
```

## Current Project Integration

### Existing Resources to Study
- `Message`: Shows ETS data layer + stubbed vectorization
- `User`/`RoomMembership`: Shows relationship patterns
- `Profile`: Shows configuration management
- `AgentCard`: Shows character-like concept (predecessor to Character system)

### Integration Points for Character System
1. **Follow Message pattern**: ETS + stubbed AshAI vectorization
2. **Use Domain organization**: Add to AshChat.Domain
3. **Relationship pattern**: belongs_to Role/Persona like User ↔ RoomMembership  
4. **Tool calling ready**: Actions can be exposed to LLMs via MCP

---

*Reference compiled from Ash Framework 3.x docs, AshAI best practices, and current codebase analysis*