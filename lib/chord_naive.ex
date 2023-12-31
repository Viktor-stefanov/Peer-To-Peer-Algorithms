defmodule ChordNaive do
  import Utils

  @doc "creates and initializesa new chord ring"
  def create(m \\ 6) do
    pid =
      spawn(fn ->
        loop_node(%{
          :pid => nil,
          :id => nil,
          :items => %{},
          :successor => %{},
          :finger_table => %{},
          :m => m
        })
      end)

    send(pid, {:init, pid})
    pid
  end

  @doc "joins the network trough the given loop_node's finger table"
  def join(loop_node) do
    pid =
      spawn(fn ->
        loop_node(%{
          :pid => nil,
          :id => nil,
          :successor => %{},
          :m => nil,
          :finger_table => %{},
          :items => %{}
        })
      end)

    send(loop_node, {:get_m_and_join, pid})
    pid
  end

  defp loop_node(state) do
    receive do
      {:init, pid} ->
        state = %{
          state
          | :pid => pid,
            :successor => %{},
            :id => calculate_id(pid, state.m),
            :items => %{}
        }

        loop_node(state)

      # send 'm' value of active loop_node to joining node
      {:get_m_and_join, pid} ->
        send(pid, {:join, pid, state.m, self()})

      # initialize joining loop_node's state and begin finding it's place in the chord ring
      {:join, pid, m, loop_node} ->
        state = %{
          state
          | :pid => pid,
            :successor => nil,
            :m => m,
            :id => calculate_id(pid, m),
            :items => %{}
        }

        send(loop_node, {:ask_to_join, pid, state.id})
        loop_node(state)

      {:make_predecessor, predecessor, id} ->
        send(predecessor, {:make_successor, state.pid, state.id})

        redistributed_items =
          for {key, value} <- state.items,
              calculate_id(key, state.m) >= id and calculate_id(key, state.m) <= state.id,
              do: {key, value}

        items =
          for {key, value} <- state.items,
              calculate_id(key, state.m) >= state.id and calculate_id(key, state.m) <= id,
              do: {key, value}

        IO.puts("redistributed items:")
        IO.inspect(redistributed_items)
        send(predecessor, {:take_items, Enum.into(redistributed_items, %{})})
        loop_node(Map.put(state, :items, Enum.into(items, %{})))

      # make the given node a successor of the current node and distribute the keys between the two nodes
      {:make_successor, node, id} ->
        loop_node(Map.put(state, :successor, %{:pid => node, :id => id}))

      # find place of joining loop_node based on ID. Condition is id > current_id and id < successor_id. Colissions are ignored as their probability is negligible
      {:ask_to_join, joining_loop_node, id} when state.successor == %{} ->
        send(state.pid, {:make_predecessor, joining_loop_node, id})
        state = Map.put(state, :successor, %{:pid => joining_loop_node, :id => id})
        IO.puts("joined chord ring successfully.")
        loop_node(state)

      {:ask_to_join, joining_loop_node, id}
      when state.id > state.successor.id and (id > state.id or id < state.successor.id) ->
        # send(joining_loop_node, {:make_successor, state.successor.pid, state.successor.id})
        send(state.successor.pid, {:make_predecessor, joining_loop_node, id})
        state = Map.put(state, :successor, %{:pid => joining_loop_node, :id => id})
        IO.puts("joined chord ring successfully.")
        loop_node(state)

      {:ask_to_join, joining_loop_node, id} when id > state.id and id < state.successor.id ->
        send(state.successor.pid, {:make_predecessor, joining_loop_node, id})
        # send(joining_loop_node, {:make_successor, state.successor.pid, state.successor.id})
        state = Map.put(state, :successor, %{:pid => joining_loop_node, :id => id})
        IO.puts("joined chord ring successfully.")
        loop_node(state)

      {:ask_to_join, joining_loop_node, id} ->
        send(state.successor.pid, {:ask_to_join, joining_loop_node, id})

      {:put, key, value} ->
        item_id = calculate_id(to_string(key), state.m)
        send(state.pid, {:put_rec, key, value, item_id})

      {:put_rec, key, value, item_id}
      when state.id > state.successor.id and (item_id < state.successor.id or item_id > state.id) ->
        send(state.successor.pid, {:store, key, value})

      {:put_rec, key, value, item_id}
      when state.id < state.successor.id and item_id in state.id..(state.successor.id - 1) ->
        send(state.successor.pid, {:store, key, value})

      {:put_rec, key, value, item_id} ->
        send(state.successor.pid, {:put_rec, key, value, item_id})

      {:store, key, value} ->
        IO.puts("stored item successfully.")
        loop_node(%{state | items: Map.put(state.items, key, value)})

      {:get, key} ->
        key_id = calculate_id(key, state.m)
        send(state.pid, {:get_rec, key_id, key})

      {:get_rec, key_id, key}
      when state.id > state.successor.id and key_id < state.successor.id ->
        send(state.successor.pid, {:display_value, key})

      {:get_rec, key_id, key} when key_id >= state.id and key_id < state.successor.id ->
        send(state.successor.pid, {:display_value, key})

      {:get_rec, key_id, key} ->
        send(state.successor.pid, {:get_rec, key_id, key})

      {:display_value, key} ->
        IO.puts("key #{key} is associated with value #{Map.get(state.items, key)}")

      {:take_items, items} ->
        loop_node(%{state | :items => Map.merge(state.items, items)})

      :leave ->
        send(state.successor.pid, {:take_items, state.items})
        send(state.pid, {:change_successor, state})

      {:change_successor, node} when node.id == state.successor.id ->
        Process.exit(node.pid, :kill)
        loop_node(%{state | :successor => node.successor})

      {:change_successor, node} ->
        send(state.successor.pid, {:change_successor, node})

      :print ->
        IO.inspect(state)
    end

    loop_node(state)
  end
end
