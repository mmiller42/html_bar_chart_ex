defmodule FloatRange do
  @moduledoc """
  Like Range, a FloatRange represents a sequence of ascending or descending
  numbers with a common difference called `step`.

  However, there are some key differences:

  1. If `step` is not defined, it defaults to being the distance between `first`
    and `last`, rather than defaulting to `1`/`-1`. Therefore, without a defined
    `step`, a FloatRange will contain only the `first` and `last` value.
  2. `first` and `last` may not be equal.
  3. Empty FloatRanges are illegal, i.e. when `first` > `last`, `step` must be >
    0; otherwise, `step` must be < 0.

  Examples:

    iex> range = FloatRange.new(0.0, 3.5)
    %FloatRange(0.0..3.5//3.5)
    iex> Enum.to_list(range)
    [0.0, 3.5]

    iex> range = FloatRange.new(0, 3.5, 0.5)
    %FloatRange(0.0..3.5//0.5)
    iex> Enum.to_list(range)
    [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5]

    iex> range = FloatRange.new(1.5, 3.5, 0.75)
    %FloatRange(1.5..3.5//0.75)
    iex> Enum.to_list(range)
    [1.5, 2.25, 3.0]

    iex> range = FloatRange.new(1.5, 3.5, 3)
    %FloatRange(1.5..3.5//3.0)
    iex> Enum.to_list(range)
    [1.5]

    iex> range = FloatRange.new(1.0, -3.5)
    %FloatRange(1.0..-3.5/-3.5)
    iex> Enum.to_list(range)
    [1.0, -3.5]

    iex> range = FloatRange.new(1.0, -3.5, -1.0)
    %FloatRange(1.0..-3.5//-1.0)
    iex> Enum.to_list(range)
    [1.0, 0.0, -1.0, -2.0, -3.0]
  """

  @enforce_keys [:first, :last, :step]
  defstruct @enforce_keys

  @type t :: %__MODULE__{first: float(), last: float(), step: float()}
  @type step :: float() | neg_integer() | pos_integer()

  @spec new(first :: number(), last :: number()) :: t()
  def new(first, last), do: new(first, last, last - first)

  @spec new(first :: number(), last :: number(), step :: step()) :: t()
  def new(first, last, step)

  def new(first, last, step) when is_integer(first) or is_integer(last) or is_integer(step),
    do: new(first / 1, last / 1, step / 1)

  def new(first, last, step)
      when is_float(first) and is_float(last) and is_float(step) and step == 0 do
    raise ArgumentError,
          "ranges (first..last//step) expect step not to be 0, got: #{print(first, last, step)}"
  end

  def new(first, last, step)
      when is_float(first) and is_float(last) and is_float(step) and first < last and step < 0 do
    raise ArgumentError,
          "ranges (first..last//step) expect step to be > 0 when first < last, got: #{print(first, last, step)}"
  end

  def new(first, last, step)
      when is_float(first) and is_float(last) and is_float(step) and first > last and step > 0 do
    raise ArgumentError,
          "ranges (first..last//step) expect step to be < 0 when first > last, got: #{print(first, last, step)}"
  end

  def new(first, last, step) when is_float(first) and is_float(last) and is_float(step) do
    %__MODULE__{first: first, last: last, step: step}
  end

  @spec size(range :: t()) :: non_neg_integer()
  def size(%__MODULE__{first: first, last: last, step: step}) do
    last
    |> Kernel.-(first)
    |> Kernel./(step)
    |> trunc()
    |> abs()
    |> Kernel.+(1)
  end

  defp print(first, last, step),
    do: "%FloatRange(#{inspect(first)}..#{inspect(last)}//#{inspect(step)})"
end

defimpl Enumerable, for: FloatRange do
  @spec reduce(range :: FloatRange.t(), acc :: Enumerable.acc(), fun :: Enumerable.reducer()) ::
          Enumerable.result()
  def reduce(%FloatRange{first: first, last: last, step: step}, acc, fun) do
    do_reduce(first, last, acc, fun, step)
  end

  @spec do_reduce(
          first :: float(),
          last :: float(),
          acc :: Enumerable.acc(),
          fun :: Enumerable.reducer(),
          step :: float()
        ) :: Enumerable.result()
  defp do_reduce(first, last, {:cont, acc}, fun, step)
       when step > 0 and first <= last
       when step < 0 and first >= last do
    do_reduce(first + step, last, fun.(first, acc), fun, step)
  end

  defp do_reduce(_first, _last, {:cont, acc}, _fun, _step), do: {:done, acc}

  defp do_reduce(_first, _last, {:halt, acc}, _fun, _step), do: {:halted, acc}

  defp do_reduce(first, last, {:suspend, acc}, fun, step),
    do: {:suspended, acc, &do_reduce(first, last, &1, fun, step)}

  @spec member?(range :: FloatRange.t(), value :: term()) :: {:ok, boolean()}
  def member?(%FloatRange{first: first, last: last, step: step}, value)
      when is_float(value) do
    cond do
      step > 0 and value < first ->
        {:ok, false}

      step > 0 and value > last ->
        {:ok, false}

      step < 0 and value > first ->
        {:ok, false}

      step < 0 and value < last ->
        {:ok, false}

      true ->
        result = (value - first) / step
        {:ok, result == trunc(result)}
    end
  end

  def member?(range, value) when is_integer(value), do: member?(range, value / 1)
  def member?(_range, _value), do: {:ok, false}

  @spec count(range :: FloatRange.t()) :: {:ok, non_neg_integer()}
  def count(range), do: {:ok, FloatRange.size(range)}

  @spec slice(range :: FloatRange.t()) ::
          {:ok, size :: pos_integer(), Enumerable.slicing_fun()}
  @spec slice(FloatRange.t()) :: {:ok, pos_integer(), (non_neg_integer(), pos_integer() -> [...])}
  def slice(range), do: {:ok, FloatRange.size(range), &slicing_fun(range, &1, &2)}

  @spec slicing_fun(range :: FloatRange.t(), start :: non_neg_integer(), length :: pos_integer()) ::
          [term()]
  defp slicing_fun(%FloatRange{first: first, step: step}, start, length),
    do: do_slice(first + start * step, step, length)

  @spec do_slice(current :: float(), step :: float(), remaining :: pos_integer()) :: [float()]
  defp do_slice(current, _step, 1), do: [current]

  defp do_slice(current, step, remaining),
    do: [current | do_slice(current + step, step, remaining - 1)]
end

defimpl Inspect, for: FloatRange do
  import Inspect.Algebra
  import Kernel, except: [inspect: 2]

  @spec inspect(range :: FloatRange.t(), opts :: Inspect.Opts.t()) :: Inspect.Algebra.t()
  def inspect(%FloatRange{first: first, last: last, step: step}, opts) do
    concat([
      "%FloatRange(",
      to_doc(first, opts),
      "..",
      to_doc(last, opts),
      "//",
      to_doc(step, opts),
      ")"
    ])
  end
end
