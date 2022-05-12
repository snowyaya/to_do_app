defmodule ToDoAppWeb.PageLive do
  use ToDoAppWeb, :live_view
  alias ToDoApp.Item

  # The @topic "live" is the WebSocket (Phoenix Channel) topic defined as a module attribute (like a Global Constant), which we will use to both subscribe to and broadcast on.
  @topic "live"

  @impl true
  def mount(_params, _session, socket) do
    # {:ok, socket}
    # subscribe to the channel
    if connected?(socket), do: ToDoAppWeb.Endpoint.subscribe(@topic)
    # add items to assigns
    {:ok, assign(socket, items: Item.list_items())}
  end

  @impl true
  def handle_event("create", %{"text" => text}, socket) do
    Item.create_item(%{text: text})
    socket = assign(socket, items: Item.list_items(), active: %Item{})

    # send the "update" event with the socket.assigns data to all the other clients on listening to the @topic.
    ToDoAppWeb.Endpoint.broadcast_from(self(), @topic, "update", socket.assigns)
    {:noreply, socket}
  end

  # We are using pattern matching on the first parameter to make sure the handle_info matches the "update" event.
  # We then assign to the socket the new list of items.
  @impl true
  def handle_info(%{event: "update", payload: %{items: items}}, socket) do
    {:noreply, assign(socket, items: items)}
  end

  def checked?(item) do
    is_nil(item.status) and item.status > 0
  end

  def completed?(item) do
    if not is_nil(item.status) and item.status > 0, do: "completed", else: ""
  end

  @impl true
  def handle_event("toggle", data, socket) do
    status = if Map.has_key?(data, "value"), do: 1, else: 0
    item = Item.get_item!(Map.get(data, "id"))
    Item.update_item(item, %{id: item.id, status: status})
    socket = assign(socket, items: Item.list_items(), active: %Item{})
    ToDoAppWeb.Endpoint.broadcast_from(self(), @topic, "update", socket.assigns)
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", data, socket) do
    Item.delete_item(Map.get(data, "id"))
    socket = assign(socket, items: Item.list_items(), active: %Item{})
    ToDoAppWeb.Endpoint.broadcast_from(self(), @topic, "update", socket.assigns)
    {:noreply, socket}
  end
end

# When using LiveView, the controller is required to implement the mount function, the entry point of the live page.
