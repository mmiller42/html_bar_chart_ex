defmodule HtmlBarChart.Legend do
  alias HtmlBarChart.Legend.LegendKey

  @type t :: %__MODULE__{
          title: String.t(),
          subtitle: String.t(),
          legend_keys: [LegendKey.t()]
        }

  @type key_tuple :: {color :: String.t(), label :: String.t()}

  @enforce_keys [:title, :subtitle, :legend_keys]
  defstruct @enforce_keys

  defmodule LegendKey do
    @type t :: %__MODULE__{label: String.t(), color: String.t(), last?: boolean()}

    @enforce_keys [:label, :color, :last?]
    defstruct @enforce_keys
  end

  @spec new(title :: String.t(), subtitle :: String.t(), keys :: [key_tuple()]) :: t()
  def new(title, subtitle, keys) do
    %__MODULE__{
      title: title,
      subtitle: subtitle,
      legend_keys:
        keys
        |> Enum.with_index()
        |> Enum.map(fn {{color, label}, index} ->
          %LegendKey{
            label: label,
            color: color,
            last?: index == Enum.count(keys) - 1
          }
        end)
    }
  end
end
