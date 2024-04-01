defmodule DeleteMe do
  alias HtmlBarChart.Config
  alias HtmlBarChart.DualComparisonChart
  alias HtmlBarChart.DualComparisonChart.Category
  alias HtmlBarChart.DualComparisonChart.Series
  alias HtmlBarChart.Template

  @spec config() :: Config.t()
  def config do
    %Config{
      width: 500,
      height: 500,
      y_axis_label_width: 72,
      x_axis_label_height: 20,
      series_indicator_height: 10,
      edge_width: 20,
      bar_gap_width: 10,
      series_gap_width: 30,
      min_grid_height: 40,
      y_axis_min_tick_step: 1.0,
      format_y_axis_tick_label:
        &HtmlBarChart.format_tick_label(&1, singular_label: "hr", plural_label: "hrs")
    }
  end

  @spec categories() :: [Category.t()]
  def categories do
    [
      %Category{label: "Off", primary_color: "#9d4bb5", secondary_color: "#ae8bf5"},
      %Category{label: "Heating", primary_color: "#1672d6", secondary_color: "#88bbf3"},
      %Category{label: "Cooling", primary_color: "#ee7850", secondary_color: "#f4a58a"}
    ]
  end

  @spec april_data() :: Series.t()
  def april_data do
    %Series{label: "April", values: [0.5, 5.0, 0.9]}
  end

  @spec march_data() :: Series.t()
  def march_data do
    %Series{label: "March", values: [0.75, 3.7, 1.5]}
  end

  def test do
    params =
      %DualComparisonChart{
        config: config(),
        title: "Living Room",
        subtitle: "HVAC April usage",
        categories: categories(),
        primary_series: april_data(),
        secondary_series: march_data()
      }
      |> DualComparisonChart.template()
      |> Template.prepare()
      |> IO.inspect()

    html = :bbmustache.render(HtmlBarChart.mustache_template(), params, key_type: :atom)

    File.write("table.html", html)
  end
end
