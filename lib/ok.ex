defmodule Ok do
  @moduledoc """
  Utility module to work with `{:ok, value} | {:error, reason}` values
  """

  @type t :: {:ok, any} | {:error, any}
  @type tenum :: {:ok, Enum.t} | {:error, any}

  @doc """
  Wrap values with {:ok, value} tuple

  ## Examples

      iex> Ok.ok(1)
      {:ok, 1}
  """
  @spec ok(any) :: {:ok, any}
  def ok(term), do: {:ok, term}


  @doc """
  Wrap error into {:error, error} tuple

  ## Examples

      iex> Ok.error(:econnrefused)
      {:error, :econnrefused}
  """
  @spec error(any) :: {:error, any}
  def error(reason), do: {:error, reason}


  @doc """
  Wrap value in {:ok, value} tuple.
  If the value is nil return {:error, reason} tuple instead

  ## Exapmles

      iex> Ok.wrap(2, :notfound)
      {:ok, 2}

      iex> Ok.wrap(nil, :notfound)
      {:error, :notfound}
  """
  @spec wrap(any, any) :: t
  def wrap(value, reason)
  def wrap(nil, reason), do: {:error, reason}
  def wrap(term, _reason), do: {:ok, term}


  @doc """
  Get value or use the fallback

  ## Exapmles

      iex> Ok.get({:ok, 1}, 0)
      1

      iex> Ok.get({:error, :notfound}, 0)
      0
  """
  @spec get(t, any) :: any
  def get(tuple, fallback)
  def get({:ok, term}, _), do: term
  def get({:error, _}, fb), do: fb


  @doc """
  Boolean OR on tuples (tuple-or, tor)

  ## Examples

      iex> Ok.tor({:ok, 1}, {:ok, 2})
      {:ok, 1}

      iex> Ok.tor({:error, "oups"}, {:ok, 2})
      {:ok, 2}

      iex> Ok.tor({:ok, 1}, {:error, "meh"})
      {:ok, 1}

      iex> Ok.tor({:error, "oups"}, {:error, "meh"})
      {:error, "meh"}
  """
  @spec tor(t, t) :: t
  def tor(tuple, tuple)
  def tor({:error, _}, next), do: next
  def tor({:ok, term}, _), do: {:ok, term}


  @doc """
  Boolean AND on tuples (tuple-and, tand)

  ## Examples

      iex> Ok.tand({:ok, 1}, {:ok, 2})
      {:ok, 2}

      iex> Ok.tand({:error, "oups"}, {:ok, 2})
      {:error, "oups"}

      iex> Ok.tand({:ok, 1}, {:error, "meh"})
      {:error, "meh"}

      iex> Ok.tand({:error, "oups"}, {:error, "meh"})
      {:error, "oups"}
  """
  @spec tand(t, t) :: t
  def tand(tuple, tuple)
  def tand({:error, reason}, _), do: {:error, reason}
  def tand({:ok, _}, next), do: next


  @doc """
  Map tuple with given fun only if it's OK

  ## Examples

      iex> Ok.map({:ok, 2}, fn x -> x * 5 end)
      {:ok, 10}

      iex> Ok.map({:error, "oups"}, fn x -> x * 5 end)
      {:error, "oups"}

      iex> {:ok, 123} |> Ok.map(& &1 + 321)
      {:ok, 444}
  """
  @spec map(t, (any -> any)) :: t
  def map(tuple, function)
  def map({:error, reason}, _), do: {:error, reason}
  def map({:ok, term}, fun), do: {:ok, fun.(term)}


  @doc """
  Run function if tuple is OK.
  Only useful for side effects

  ## Examples

      iex> Ok.each({:ok, 2}, fn x -> x * 5 end)
      {:ok, 2}

      iex> Ok.each({:error, "oups"}, fn x -> x * 5 end)
      {:error, "oups"}

      iex> {:ok, 123} |> Ok.map(&IO.inspect/1)
      {:ok, 123}
  """
  @spec each(t, (any -> any)) :: t
  def each(tuple, function)
  def each({:error, reason}, _), do: {:error, reason}
  def each({:ok, term}, fun) do
    fun.(term)
    {:ok, term}
  end


  @doc """
  Flat map tuple with given fun only if it's OK

  ## Examples

      iex> Ok.flat_map({:ok, 2}, fn x -> {:ok, x + 1} end)
      {:ok, 3}

      iex> Ok.flat_map({:ok, 2}, fn _ -> {:error, "oups"} end)
      {:error, "oups"}

      iex> Ok.flat_map({:error, "oups"}, fn x -> {:ok, x + 1} end)
      {:error, "oups"}
  """
  @spec flat_map(t, (any -> t)) :: t
  def flat_map(typle, function)
  def flat_map({:error, reason}, _fun), do: {:error, reason}
  def flat_map({:ok, term}, fun), do: fun.(term)

  @doc """
  Flatten (also called "join") nested tuples into single one

  ## Examples

      iex> Ok.flatten({:ok, {:ok, 1}})
      {:ok, 1}

      iex> Ok.flatten({:error, {:ok, "hm"}})
      {:error, {:ok, "hm"}}

      iex> Ok.flatten({:ok, {:error, "oups"}})
      {:error, "oups"}
  """
  @spec flatten({:ok, t} | {:error, any}) :: t
  def flatten(nested_tuple)
  def flatten({:error, reason}), do: {:error, reason}
  def flatten({:ok, {:error, reason}}), do: {:error, reason}
  def flatten({:ok, {:ok, term}}), do: {:ok, term}


  @doc """
  Convert list of ok/error tuples into ok/error tuple of list

  ## Examples

      iex> Ok.seq([{:ok, 1}, {:ok, 2}, {:ok, 3}])
      {:ok, [1,2,3]}

      iex> Ok.seq([{:error, "oups"}, {:error, "meh"}])
      {:error, ["oups", "meh"]}

      iex> Ok.seq([{:ok, 1}, {:error, "bad 2"}, {:error, "bad 3"}, {:ok, 4}])
      {:error, ["bad 2", "bad 3"]}

      iex> Ok.seq([])
      {:ok, []}
  """
  @spec seq([t]) :: {:ok, list} | {:error, any}
  def seq(list_of_tuples)
  def seq([]), do: {:ok, []}
  def seq(list), do: seq(list, {:ok, []})
  defp seq([], {:ok, oks}), do: {:ok, Enum.reverse(oks)}
  defp seq([], {:error, errs}), do: {:error, Enum.reverse(errs)}
  defp seq([{:ok, h} | t], {:ok, oks}), do: seq(t, {:ok, [h | oks]})
  defp seq([{:ok, _h} | t], {:error, errs}), do: seq(t, {:error, errs})
  defp seq([{:error, h} | t], {:ok, _oks}), do: seq(t, {:error, [h]})
  defp seq([{:error, h} | t], {:error, errs}), do: seq(t, {:error, [h | errs]})


  @doc """
  Map tuple with enum given fun only if it's OK

  ## Examples

      iex> Ok.map_enum({:ok, [1,2,3]}, fn x -> x + 1 end)
      {:ok, [2,3,4]}

      iex> Ok.map_enum({:error, "oups"}, fn x -> x + 1 end)
      {:error, "oups"}
  """
  @spec map_enum(tenum, (any -> any)) :: tenum
  def map_enum(tuple_with_enum, function)
  def map_enum(t, fun), do: map(t, &Enum.map(&1, fun))

  @doc """
  Flat map tuple with enum given fun only if it's OK

  ## Examples

      iex> Ok.flat_map_enum({:ok, [1,2,3]}, fn x -> {:ok, x + 1} end)
      {:ok, [2,3,4]}

      iex> Ok.map_enum({:error, "oups"}, fn x -> x + 1 end)
      {:error, "oups"}

      iex> Ok.flat_map_enum {:ok, [1,2,3]}, fn
      ...>   1 -> {:ok, 1}
      ...>   x -> {:error, "\#{x} is bad"}
      ...> end
      {:error, ["2 is bad", "3 is bad"]}
  """
  @spec flat_map_enum(tenum, (any -> any)) :: tenum
  def flat_map_enum(tuple_with_enum, function)
  def flat_map_enum(t, fun), do: flat_map(t, fn xs -> xs |> Enum.map(fun) |> seq end)
end
