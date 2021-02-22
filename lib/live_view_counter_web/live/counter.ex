defmodule LiveViewCounterWeb.Counter do
  use Phoenix.LiveView

  alias LiveViewCounter.Count
  alias Phoenix.PubSub
  alias LiveViewCounter.Presence

  @topic Count.topic
  @presence_topic "presence"

  def mount(_params, _session, socket) do
    PubSub.subscribe(LiveViewCounter.PubSub, @topic)

    Presence.track(self(), @presence_topic, socket.id, %{region: fly_region()})
    LiveViewCounterWeb.Endpoint.subscribe(@presence_topic)

    list = Presence.list(@presence_topic)
    present = presence_by_region(list)
    counts = Map.new([{fly_region(), Count.current()}])

    {:ok, assign(socket, counts: counts, present: present, region: fly_region()) }
  end

  def fly_region do
    System.get_env("FLY_REGION", "unknown")
  end

  def handle_event("inc", _, %{ assigns: %{ counts: counts } } = socket) do
    c = Count.incr()
    {:noreply, assign(socket, counts: Map.put(counts, fly_region(), c))}
  end

  def handle_event("dec", _, %{ assigns: %{ counts: counts } } = socket) do
    c = Count.decr()
    {:noreply, assign(socket, counts: Map.put(counts, fly_region(), c))}
  end

  def handle_event("ping", _, socket) do
    {:reply, %{}, socket}
  end

  def handle_info(
    {:count, count, :region, region},
    %{ assigns: %{ counts: counts } } = socket
    ) do

    new_counts = Map.put(counts, region, count)

    {:noreply, assign(socket, counts: new_counts)}
  end

  def handle_info(
        %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
        %{assigns: %{present: present}} = socket
      ) do

    adds = presence_by_region(joins)
    subtracts = presence_by_region(leaves)

    new_present = Map.merge(present, adds, fn _k, v1, v2 ->
      v1 + v2
    end)

    new_present = Map.merge(new_present, subtracts, fn _k, v1, v2 ->
      v1 - v2
    end)


    {:noreply, assign(socket, :present, new_present)}
  end

  @type presence_entry :: {any(), %{metas: list(%{ atom() => any() })}}
  @spec presence_by_region(list(presence_entry)) :: %{any() =>  non_neg_integer()}
  def presence_by_region(presence) do
    result = presence
              |> Enum.map(&(elem(&1,1)))
              |> Enum.flat_map(&Map.get(&1, :metas))
              |> Enum.filter(&Map.has_key?(&1, :region))
              |> Enum.group_by(&Map.get(&1, :region))
              |> Enum.sort_by(&(elem(&1, 0)))
              |> Map.new(fn {k,v}-> {k, length(v) } end)

    result
  end

  def render(assigns) do
    ~L"""
    <div>
      <h1>The count is: <%= Map.values(@counts) |> Enum.sum %></h1>
      <button phx-click="dec">-</button>
      <button phx-click="inc">+</button>

      <table>
        <tr>
          <th>Region</th>
          <th>Users</th>
          <th>Clicks</th>
        </tr>
        <%= for {k, v} <- @present do %>
        <tr>
          <th class="region">
            <img src="https://fly.io/ui/images/<%= k %>.svg" />
            <%= k %>
          </th>
          <td><%= v %></td>
          <td><%= Map.get(@counts, to_string(k), 0) %></td>
        </tr>
        <% end %>
      </table>
    </div>
    <div>
      Latency <span id="rtt" phx-hook="RTT" phx-update="ignore"></span>
    </div>
    <div>
      Connected to <%= @region || "?" %>
    </div>
    """
  end
end

# <!--<img class="icon" src="<%= Routes.static_path(LiveViewCounterWeb.Endpoint, "/images/icons/#{k}.svg") %>" alt="<%= k %> flag"/>
