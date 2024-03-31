defmodule HtmlBarChart.Template do
  alias HtmlBarChart.Config
  alias HtmlBarChart.Data
  alias HtmlBarChart.Legend
  alias HtmlBarChart.Template.Chart
  alias HtmlBarChart.Template.GridRow
  alias HtmlBarChart.Template.GridCell
  alias HtmlBarChart.Template.XAxisCell

  @type t :: %__MODULE__{
          chart: Chart.t(),
          legend: Legend.t(),
          col_count: pos_integer()
        }

  @enforce_keys [:chart, :legend, :col_count]
  defstruct @enforce_keys

  defmodule Chart do
    alias HtmlBarChart.Template.GridRow
    alias HtmlBarChart.Template.XAxisCell

    @type t :: %__MODULE__{
            # When embedding lists of data, rather than simply using a list of
            # structs, each struct gets wrapped in a map. This makes referencing
            # the variable within a loop in the Mustache template less ambiguous
            grid_rows: [%{grid_row: GridRow.t()}],
            x_axis_cells: [%{x_axis_cell: XAxisCell.t()}],
            x_axis_label_height: pos_integer(),
            series_indicator_height: pos_integer(),
            x_axis_height: pos_integer(),
            y_axis_label_width: pos_integer(),
            grid_cell_height: pos_integer(),
            edge_width: pos_integer(),
            bar_gap_width: pos_integer(),
            series_gap_width: pos_integer(),
            bar_width: pos_integer()
          }

    @enforce_keys [
      :grid_rows,
      :x_axis_cells,
      :x_axis_label_height,
      :series_indicator_height,
      :x_axis_height,
      :y_axis_label_width,
      :grid_cell_height,
      :edge_width,
      :bar_gap_width,
      :series_gap_width,
      :bar_width
    ]
    defstruct @enforce_keys
  end

  defmodule GridRow do
    alias HtmlBarChart.Template.GridCell

    @type t :: %__MODULE__{
            label: String.t(),
            grid_cells: [%{grid_cell: GridCell.t()}],
            first?: boolean(),
            last?: boolean()
          }

    @enforce_keys [:label, :grid_cells, :first?, :last?]
    defstruct @enforce_keys
  end

  defmodule GridCell do
    @type t :: %__MODULE__{
            bar_gap?: boolean(),
            series_gap?: boolean(),
            empty_bar?: boolean(),
            bar?: boolean(),
            bar_color: String.t() | nil,
            bar_height: non_neg_integer()
          }

    defstruct bar_gap?: false,
              series_gap?: false,
              empty_bar?: false,
              bar?: false,
              bar_color: nil,
              bar_height: 0

    @spec bar_gap_cell() :: t()
    def bar_gap_cell, do: %__MODULE__{bar_gap?: true}

    @spec series_gap_cell() :: t()
    def series_gap_cell, do: %__MODULE__{series_gap?: true}

    @spec empty_bar_cell() :: t()
    def empty_bar_cell, do: %__MODULE__{empty_bar?: true}

    @spec bar_cell(height :: pos_integer(), color :: String.t()) :: t()
    def bar_cell(height, color), do: %__MODULE__{bar?: true, bar_color: color, bar_height: height}
  end

  defmodule XAxisCell do
    @type t :: %__MODULE__{
            series_gap?: boolean(),
            series_label?: boolean(),
            colspan: pos_integer() | nil,
            label: String.t() | nil,
            width: pos_integer() | nil
          }

    defstruct series_gap?: false, series_label?: false, colspan: nil, label: nil, width: nil

    @spec series_gap_cell() :: t()
    def series_gap_cell, do: %__MODULE__{series_gap?: true}

    @spec series_label_cell(width :: pos_integer(), colspan :: pos_integer(), label :: String.t()) ::
            t()
    def series_label_cell(width, colspan, label),
      do: %__MODULE__{series_label?: true, label: label, colspan: colspan, width: width}
  end

  @spec new(Config.t(), Data.t(), Legend.t()) :: t()
  def new(
        %Config{
          x_axis_label_height: x_axis_label_height,
          series_indicator_height: series_indicator_height,
          y_axis_label_width: y_axis_label_width,
          edge_width: edge_width,
          bar_gap_width: bar_gap_width,
          series_gap_width: series_gap_width
        } = config,
        data,
        legend
      ) do
    %__MODULE__{
      chart: %Chart{
        x_axis_label_height: x_axis_label_height,
        series_indicator_height: series_indicator_height,
        y_axis_label_width: y_axis_label_width,
        edge_width: edge_width,
        bar_gap_width: bar_gap_width,
        series_gap_width: series_gap_width,
        bar_width: bar_width(config, data),
        x_axis_height: Config.x_axis_height(config),
        grid_cell_height: grid_cell_height(config, data),
        grid_rows: grid_rows(config, data),
        x_axis_cells: x_axis_cells(config, data)
      },
      legend: legend,
      col_count: col_count(data)
    }
  end

  @spec col_count(data :: Data.t()) :: pos_integer()
  defp col_count(data) do
    y_axis_and_edges_count = 3
    bar_count = Data.bar_count(data)
    bar_gap_count = Data.bar_gap_count(data)
    series_gap_count = Data.series_gap_count(data)

    y_axis_and_edges_count + bar_count + bar_gap_count + series_gap_count
  end

  @spec bar_width(config :: Config.t(), data :: Data.t()) :: pos_integer()
  defp bar_width(
         %Config{
           edge_width: edge_width,
           bar_gap_width: bar_gap_width,
           series_gap_width: series_gap_width
         } = config,
         data
       ) do
    edges_width = edge_width * 2
    series_gaps_width = Data.series_gap_count(data) * series_gap_width
    bar_gaps_width = Data.bar_gap_count(data) * bar_gap_width
    available_width = Config.grid_width(config) - edges_width - series_gaps_width - bar_gaps_width

    (available_width / Data.bar_count(data))
    |> trunc()
    |> max(1)
  end

  @spec grid_cell_height(config :: Config.t(), data :: Data.t()) :: pos_integer()
  defp grid_cell_height(config, data) do
    config
    |> Config.grid_height()
    |> Kernel./(Data.tick_count(data))
    |> trunc()
    |> max(1)
  end

  @spec bar_segment_height(
          config :: Config.t(),
          data :: Data.t(),
          value :: float(),
          tick_range :: FloatRange.t()
        ) :: non_neg_integer()
  defp bar_segment_height(config, data, value, tick_range) do
    value
    |> Kernel.-(tick_range.first)
    |> max(0)
    |> min(tick_range.last - tick_range.first)
    |> Kernel./(tick_range.last - tick_range.first)
    |> Kernel.*(grid_cell_height(config, data))
    |> trunc()
  end

  @spec grid_rows(Config.t(), Data.t()) :: [%{grid_row: GridRow.t()}]
  defp grid_rows(config, %Data{axis_ticks: axis_ticks} = data) do
    axis_ticks
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.map(fn {%Data.Tick{label: label} = tick, index} ->
      %{
        grid_row: %GridRow{
          label: label,
          grid_cells: grid_cells(config, data, tick),
          first?: index == 0,
          last?: index == Enum.count(axis_ticks) - 1
        }
      }
    end)
  end

  @spec grid_cells(Config.t(), Data.t(), Data.Tick.t()) :: [%{grid_cell: GridCell.t()}]
  defp grid_cells(
         config,
         %Data{series: series} = data,
         %Data.Tick{range: range}
       ) do
    series
    |> Enum.map(fn %Data.Series{points: points} ->
      points
      |> Enum.map(&bar_cell(config, data, &1, range))
      |> Enum.intersperse(GridCell.bar_gap_cell())
    end)
    |> Enum.intersperse(GridCell.series_gap_cell())
    |> Enum.flat_map(fn
      %GridCell{} = cell -> [%{grid_cell: cell}]
      cells -> Enum.map(cells, &%{grid_cell: &1})
    end)
  end

  @spec bar_cell(Config.t(), Data.t(), Data.Point.t(), FloatRange.t()) :: GridCell.t()
  defp bar_cell(config, data, %Data.Point{value: value, color: color}, range) do
    config
    |> bar_segment_height(data, value, range)
    |> case do
      0 ->
        GridCell.empty_bar_cell()

      height ->
        GridCell.bar_cell(height, color)
    end
  end

  @spec x_axis_cells(Config.t(), Data.t()) :: [%{x_axis_cell: XAxisCell.t()}]
  defp x_axis_cells(config, %Data{series: series} = data) do
    series
    |> Enum.map(&x_axis_cell(config, data, &1))
    |> Enum.intersperse(XAxisCell.series_gap_cell())
    |> Enum.map(&%{x_axis_cell: &1})
  end

  @spec x_axis_cell(Config.t(), Data.t(), Data.Series.t()) :: XAxisCell.t()
  defp x_axis_cell(
         %Config{bar_gap_width: gap_width} = config,
         data,
         %Data.Series{label: label} = series
       ) do
    bar_count = Data.bar_count(series)
    colspan = 2 * bar_count - 1
    width = bar_count * bar_width(config, data) + (bar_count - 1) * gap_width
    XAxisCell.series_label_cell(width, colspan, label)
  end
end
