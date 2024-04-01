defmodule HtmlBarChart.Data do
  alias HtmlBarChart.Config
  alias HtmlBarChart.Data.Series
  alias HtmlBarChart.Data.Tick

  @type t :: %__MODULE__{
          series: [Series.t()],
          axis_ticks: [Tick.t()]
        }

  @enforce_keys [:series, :axis_ticks]
  defstruct @enforce_keys

  defmodule Series do
    alias HtmlBarChart.Data.Point

    @type t :: %__MODULE__{
            label: String.t(),
            points: [Point.t()]
          }

    @enforce_keys [:label, :points]
    defstruct @enforce_keys
  end

  defmodule Point do
    @type t :: %__MODULE__{
            value: float(),
            color: String.t()
          }

    @enforce_keys [:value, :color]
    defstruct @enforce_keys
  end

  defmodule Tick do
    alias HtmlBarChart.Config
    alias HtmlBarChart.Data.Series

    @type t :: %__MODULE__{
            label: String.t(),
            range: FloatRange.t()
          }

    @enforce_keys [:label, :range]
    defstruct @enforce_keys

    @spec ticks(series :: [Series.t()], config :: Config.t()) :: [t()]
    def ticks(
          series,
          %Config{
            y_axis_min_tick_step: min_tick_step,
            format_y_axis_tick_label: format_label,
            min_grid_height: min_grid_height
          } = config
        ) do
      max_value =
        series
        |> Enum.flat_map(& &1.points)
        |> Enum.max_by(& &1.value)
        |> then(& &1.value)

      max_tick_value = ceil_to(max_value, min_tick_step) + min_tick_step
      max_tick_count = trunc(Config.grid_height(config) / min_grid_height)

      step = (max_tick_value / max_tick_count) |> Float.ceil() |> max(min_tick_step)

      0.0
      |> FloatRange.new(max_tick_value, step)
      |> Enum.map(fn range_start ->
        range = FloatRange.new(range_start, range_start + step)
        label = format_label.(range)

        %__MODULE__{label: label, range: range}
      end)
    end

    @spec ceil_to(value :: float(), multiple :: float()) :: float()
    defp ceil_to(value, multiple), do: Float.ceil(value / multiple) * multiple
  end

  @spec new(series :: [Series.t()], config :: Config.t()) :: t()
  def new(series, config),
    do: %__MODULE__{series: series, axis_ticks: Tick.ticks(series, config)}

  @spec tick_count(data :: t()) :: non_neg_integer()
  def tick_count(%__MODULE__{axis_ticks: axis_ticks}), do: Enum.count(axis_ticks)

  @spec series_count(data :: t()) :: non_neg_integer()
  def series_count(%__MODULE__{series: series}), do: Enum.count(series)

  @spec bar_count(data_or_series :: t() | Series.t()) :: non_neg_integer()
  def bar_count(%__MODULE__{series: series}), do: Enum.reduce(series, 0, &(bar_count(&1) + &2))
  def bar_count(%Series{points: points}), do: Enum.count(points)

  @spec bar_gap_count(data_or_series :: t() | Series.t()) :: non_neg_integer()
  def bar_gap_count(%__MODULE__{series: series}),
    do: Enum.reduce(series, 0, &(bar_gap_count(&1) + &2))

  def bar_gap_count(series), do: max(bar_count(series) - 1, 0)

  @spec series_gap_count(data :: t()) :: non_neg_integer()
  def series_gap_count(data), do: max(series_count(data) - 1, 0)
end
