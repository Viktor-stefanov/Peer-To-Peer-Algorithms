defmodule Utils do
  def calculate_id(item, m) when is_pid(item) do
    :crypto.hash(:sha, :erlang.pid_to_list(item))
    |> Base.encode16()
    |> String.to_integer(16)
    |> Integer.mod(2 ** m)
  end

  def calculate_id(item, m) do
    :crypto.hash(:sha, to_string(item))
    |> Base.encode16()
    |> String.to_integer(16)
    |> Integer.mod(2 ** m)
  end
end
