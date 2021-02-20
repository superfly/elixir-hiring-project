defmodule LiveViewCounterWeb.Counter do
  use Phoenix.LiveView

  alias LiveViewCounterWeb.Router.Helpers, as: Routes
  alias LiveViewCounter.Count
  alias Phoenix.PubSub
  alias LiveViewCounter.Presence

  @topic Count.topic
  @presence_topic "presence"

  def mount(_params, _session, socket) do
    PubSub.subscribe(LiveViewCounter.PubSub, @topic)

    region = System.get_env("FLY_REGION") || "<unknown>"
    Presence.track(self(), @presence_topic, socket.id, %{region: region})
    LiveViewCounterWeb.Endpoint.subscribe(@presence_topic)

    list = Presence.list(@presence_topic)
    present = presence_by_region(list)

    {:ok, assign(socket, val: Count.current(), present: present) }
  end

  def handle_event("inc", _, socket) do
    {:noreply, assign(socket, :val, Count.incr())}
  end

  def handle_event("dec", _, socket) do
    {:noreply, assign(socket, :val, Count.decr())}
  end

  def handle_event("ping", _, socket) do
    {:reply, %{}, socket}
  end

  def handle_info({:count, count}, socket) do
    {:noreply, assign(socket, val: count)}
  end

  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        %{assigns: %{present: present}} = socket
      ) do

    adds = presence_by_region(joins)
    subtracts = presence_by_region(leaves)

    new_present = %{}
    for {k,v} <- adds do
      new_present = Map.put(new_present, k, (new_present[k] || 0) + length(v))
    end
    for {k,v} <- subtracts do
      new_present = Map.put(new_present, k, (new_present[k] || 0) - length(v))
    end

    #new_present = present + map_size(joins) - map_size(leaves)


    {:noreply, assign(socket, :present, new_present)}
  end

  @spec presence_by_region(Enum) :: Map
  def presence_by_region(list) do
    list
    # |> IO.inspect
    |> Enum.flat_map(fn {_, %{metas: metas}} -> metas end)
    |> Enum.filter(fn m -> m[:region] != nil end)
    |> Enum.group_by(fn r -> Map.get(r, :region) end)
    # |> IO.inspect
  end

  def render(assigns) do
    ~L"""
    <div>
      <h1>The count is: <%= @val %></h1>
      <button phx-click="dec">-</button>
      <button phx-click="inc">+</button>
      <h1>Current users</h1>
      <%= for {k,v} <- @present do %>
      <h2>
      <span class="region">
        <%= k %></span> <%= length(v) %>
      </h2>
      <% end %>
    </div>
    <div>
      Latency <span id="rtt" phx-hook="RTT" phx-update="ignore"></span>
    </div>
    """
  end
end

# <!--<img class="icon" src="<%= Routes.static_path(LiveViewCounterWeb.Endpoint, "/images/icons/#{k}.svg") %>" alt="<%= k %> flag"/>
