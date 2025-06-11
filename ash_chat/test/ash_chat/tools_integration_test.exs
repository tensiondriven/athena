defmodule AshChat.ToolsIntegrationTest do
  use ExUnit.Case, async: false
  
  alias AshChat.Tools
  alias AshChat.Tools.Shell
  alias AshChat.Resources.{Event, Room, User}
  
  setup do
    # Clean up - Event uses ETS so we just need to clear rooms/users
    Room.read!() |> Enum.each(&Room.destroy!/1)
    User.read!() |> Enum.each(&User.destroy!/1)
    
    # Create test context
    {:ok, user} = User.create(%{
      name: "Test Agent",
      email: "agent@test.com"
    })
    
    {:ok, room} = Room.create(%{
      title: "Test Room"
    })
    
    context = %{
      agent_id: user.id,
      room_id: room.id
    }
    
    %{context: context, user: user, room: room}
  end
  
  describe "tool definitions" do
    test "all tools have required fields" do
      tools = Tools.list()
      assert length(tools) > 0
      
      for tool <- tools do
        assert tool.name != nil
        assert tool.description != nil
        assert tool.parameters != nil
        assert is_function(tool.function, 2)
      end
    end
    
    test "shell_command tool is included" do
      tools = Tools.list()
      shell_tool = Enum.find(tools, &(&1.name == "shell_command"))
      
      assert shell_tool != nil
      assert shell_tool.description =~ "whitelisted"
    end
    
    test "get_current_time tool is included" do
      tools = Tools.list()
      time_tool = Enum.find(tools, &(&1.name == "get_current_time"))
      
      assert time_tool != nil
      assert time_tool.description =~ "date"
      assert time_tool.description =~ "sunset"
    end
  end
  
  describe "shell command execution" do
    test "whitelisted commands work", %{context: context} do
      tools = Tools.list()
      shell_tool = Enum.find(tools, &(&1.name == "shell_command"))
      
      result = shell_tool.function.(%{"command" => "echo hello"}, context)
      
      assert result.success == true
      assert result.output =~ "hello"
    end
    
    test "non-whitelisted commands are rejected", %{context: context} do
      tools = Tools.list()
      shell_tool = Enum.find(tools, &(&1.name == "shell_command"))
      
      result = shell_tool.function.(%{"command" => "rm -rf /"}, context)
      
      assert result.success == false
      assert result.error =~ "not whitelisted"
      assert result.retry_hint != nil
    end
    
    test "shell commands create events", %{context: context} do
      {:ok, initial_events} = Event.recent(%{limit: 10})
      initial_count = length(initial_events)
      
      # Execute a command
      Shell.execute("pwd", context)
      
      # Check events were created
      {:ok, new_events} = Event.recent(%{limit: 10})
      assert length(new_events) > initial_count
      
      # Should have at least start and complete events
      event_types = Enum.map(new_events, & &1.event_type)
      assert "tool_call_started" in event_types
      assert "tool_call_completed" in event_types
    end
  end
  
  describe "event query tool" do
    test "can retrieve recent events", %{context: context} do
      # Create some test events
      for i <- 1..5 do
        Event.create(%{
          timestamp: DateTime.utc_now(),
          event_type: "test_event_#{i}",
          source_id: "test",
          source_path: "test",
          content: "Test event #{i}",
          description: "Test event number #{i}"
        })
      end
      
      tools = Tools.list()
      events_tool = Enum.find(tools, &(&1.name == "get_recent_events"))
      
      result = events_tool.function.(%{"limit" => 3}, context)
      
      assert result.success == true
      assert result.count == 3
      assert length(result.events) == 3
    end
    
    test "can filter events by type", %{context: context} do
      # Create events of different types
      Event.create(%{
        timestamp: DateTime.utc_now(),
        event_type: "special_type",
        source_id: "test",
        source_path: "test",
        content: "Special event"
      })
      
      Event.create(%{
        timestamp: DateTime.utc_now(),
        event_type: "other_type",
        source_id: "test",
        source_path: "test",
        content: "Other event"
      })
      
      tools = Tools.list()
      events_tool = Enum.find(tools, &(&1.name == "get_recent_events"))
      
      result = events_tool.function.(%{
        "event_type" => "special_type",
        "limit" => 10
      }, context)
      
      assert result.success == true
      assert Enum.all?(result.events, &(&1.type == "special_type"))
    end
  end
  
  describe "time tool" do
    test "can get current time for location", %{context: context} do
      tools = Tools.list()
      time_tool = Enum.find(tools, &(&1.name == "get_current_time"))
      
      result = time_tool.function.(%{"location" => "chicago"}, context)
      
      assert result.success == true
      assert result.date != nil
      assert result.time != nil
      assert result.location == "Chicago"
      assert result.timezone == "America/Chicago"
    end
    
    test "defaults to Madison when no location provided", %{context: context} do
      tools = Tools.list()
      time_tool = Enum.find(tools, &(&1.name == "get_current_time"))
      
      result = time_tool.function.(%{}, context)
      
      assert result.success == true
      assert result.location == "Madison"
    end
    
    test "time tool creates events", %{context: context} do
      tools = Tools.list()
      time_tool = Enum.find(tools, &(&1.name == "get_current_time"))
      
      # Get initial event count
      {:ok, initial_events} = Event.recent(%{limit: 10})
      initial_count = length(initial_events)
      
      # Call the time tool
      _result = time_tool.function.(%{"location" => "chicago"}, context)
      
      # Check events were created
      {:ok, new_events} = Event.recent(%{limit: 10})
      assert length(new_events) > initial_count
      
      # Should have tool call events
      event_types = Enum.map(new_events, & &1.event_type)
      assert "tool_call_started" in event_types || "tool_call_completed" in event_types
    end
  end
end