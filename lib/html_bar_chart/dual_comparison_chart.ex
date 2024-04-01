defmodule HtmlBarChart.DualComparisonChart do
  alias HtmlBarChart.Config
  alias HtmlBarChart.Data
  alias HtmlBarChart.DualComparisonChart.Category
  alias HtmlBarChart.DualComparisonChart.Series
  alias HtmlBarChart.Legend
  alias HtmlBarChart.Template

  @type t :: %__MODULE__{
          config: Config.t(),
          title: String.t(),
          subtitle: String.t(),
          categories: [Category.t()],
          primary_series: Series.t(),
          secondary_series: Series.t()
        }

  @enforce_keys ~w(config title subtitle categories primary_series secondary_series)a
  defstruct @enforce_keys

  defmodule Category do
    alias HtmlBarChart.DualComparisonChart.Series

    @type t :: %__MODULE__{
            label: String.t(),
            primary_color: String.t(),
            secondary_color: String.t()
          }

    @enforce_keys [:label, :primary_color, :secondary_color]
    defstruct @enforce_keys
  end

  defmodule Series do
    @type t :: %__MODULE__{label: String.t(), values: [number()]}

    @enforce_keys [:label, :values]
    defstruct @enforce_keys
  end

  @spec template(t()) :: Template.t()
  def template(%__MODULE__{
        config: config,
        title: title,
        subtitle: subtitle,
        categories: categories,
        primary_series: primary_series,
        secondary_series: secondary_series
      }) do
    category_count = Enum.count(categories)
    primary_series_colors = Enum.map(categories, & &1.primary_color)
    secondary_series_colors = Enum.map(categories, & &1.secondary_color)

    data =
      [{primary_series, primary_series_colors}, {secondary_series, secondary_series_colors}]
      |> Enum.map(fn {%Series{label: label, values: values}, series_colors} ->
        if Enum.count(values) == category_count do
          %Data.Series{
            label: label,
            points:
              values
              |> Enum.with_index()
              |> Enum.map(fn {value, index} ->
                %Data.Point{value: value / 1, color: Enum.at(series_colors, index)}
              end)
          }
        else
          raise ArgumentError,
                "Expected length of values to be #{inspect(category_count)}, got: #{inspect(Enum.count(values))}"
        end
      end)
      |> Data.new(config)

    legend = Legend.new(title, subtitle, Enum.map(categories, &{&1.primary_color, &1.label}))

    Template.new(config, data, legend)
  end
end
