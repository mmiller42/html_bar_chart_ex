defmodule HtmlBarChart.Config do
  @type t :: %__MODULE__{
          width: pos_integer(),
          height: pos_integer(),
          y_axis_label_width: pos_integer(),
          x_axis_label_height: pos_integer(),
          series_indicator_height: pos_integer(),
          edge_width: non_neg_integer(),
          bar_gap_width: non_neg_integer(),
          series_gap_width: non_neg_integer(),
          min_grid_height: pos_integer(),
          y_axis_min_tick_step: float(),
          format_y_axis_tick_label: (FloatRange.t() -> String.t())
        }

  @enforce_keys [
    :width,
    :height,
    :y_axis_label_width,
    :x_axis_label_height,
    :series_indicator_height,
    :edge_width,
    :bar_gap_width,
    :series_gap_width,
    :min_grid_height,
    :y_axis_min_tick_step,
    :format_y_axis_tick_label
  ]
  defstruct @enforce_keys

  @spec grid_width(config :: t()) :: pos_integer()
  def grid_width(%__MODULE__{
        width: width,
        y_axis_label_width: y_axis_label_width
      }),
      do: max(width - y_axis_label_width, 1)

  @spec grid_height(config :: t()) :: pos_integer()
  def grid_height(%__MODULE__{height: height} = config),
    do: max(height - x_axis_height(config), 1)

  @spec x_axis_height(config :: t()) :: pos_integer()
  def x_axis_height(%__MODULE__{
        x_axis_label_height: x_axis_label_height,
        series_indicator_height: series_indicator_height
      }),
      do: max(x_axis_label_height + series_indicator_height, 1)
end
