defmodule Test do
  def start(node, n \\ 1000) do
    nodes = for _ <- 1..n, do: Chord.join(node)
    loop_pid = spawn(fn -> loop() end)

    receive do
      _ -> nil
    after
      2000 -> nil
    end

    for pid <- nodes, do: send(pid, {:check, loop_pid})
    nodes
  end

  def loop do
    receive do
      {:state, state} ->
        case state.successor do
          nil -> IO.puts("bad")
          _ -> nil
        end
    end

    loop()
  end
end
