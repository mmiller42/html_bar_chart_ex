defmodule HtmlBarChart do
  @type format_tick_label_opt ::
          {:singular_label, String.t()}
          | {:plural_label, String.t()}
          | {:precision, Float.precision_range()}
  @type format_tick_label_opts :: [format_tick_label_opt()]

  @spec format_tick_label(range :: FloatRange.t(), opts :: format_tick_label_opts()) :: String.t()
  def format_tick_label(%FloatRange{first: first}, opts) do
    singular_label = Keyword.fetch!(opts, :singular_label)
    plural_label = Keyword.fetch!(opts, :plural_label)
    precision = Keyword.get(opts, :precision, 1)

    first
    |> to_number()
    |> case do
      0 -> "0"
      1 -> "1 #{singular_label}"
      int when is_integer(int) -> "#{int} #{plural_label}"
      float -> "#{Float.round(float, precision)} #{plural_label}"
    end
  end

  @spec to_number(float :: float()) :: number()
  defp to_number(float) do
    int = trunc(float)
    if int == float, do: int, else: float
  end

  @spec mustache_template() :: String.t()
  def mustache_template do
    """
    <table class="chart" border="0" cellpadding="0" cellspacing="0" frame="false" bgcolor="#ffffff" style="border-collapse: collapse">
      <tbody>
        <tr class="chart-legend-row">
          <td class="chart-legend" colspan="{{col_count}}" style="padding-bottom: 12px">
            <table class="legend" border="0" cellpadding="0" cellspacing="0" frame="false" bgcolor="#ffffff" style="border-collapse: collapse" width="100%">
              <tbody>
                <tr>
                  <td class="legend-title" align="left" valign="top" style="font: 600 14px/20px 'Open Sans', Arial, Helvetica, sans-serif">
                    <p style="margin: 0 0 0 16px; padding: 0">
                      <span style="color: #494d52">{{legend.title}}</span>
                      <br />
                      <span style="font-size: 12px; color: #aaaaaa">{{legend.subtitle}}</span>
                    </p>
                  </td>
                  <td class="legend-keys" align="right" valign="top" style="font: 600 14px 'Open Sans', Arial, Helvetica, sans-serif">
                    {{#legend.legend_keys}}
                      <span style="color: {{legend_key.color}}">{{legend_key.label}}</span>
                      {{^legend_key.last?}}
                        &nbsp;&nbsp;&nbsp;&nbsp;
                      {{/legend_key.last?}}
                    {{/legend.legend_keys}}
                  </td>
                </tr>
              </tbody>
            </table>
          </td>
        </tr>
        {{#chart.grid_rows}}
          <tr class="grid-row">
            <td class="y-axis-label" width="{{chart.y_axis_label_width}}" {{^grid_row.first?}}height="{{chart.grid_cell_height}}" {{/grid_row.first?}}align="right" valign="bottom" style="font: 12px 'Open Sans', Arial, Helvetica, sans-serif; color: #000000;{{^grid_row.first?}} border-right: 1px solid #cccccc{{/grid_row.first?}}">
              <span style="padding-right: 8px; color: #494d52">{{grid_row.label}}</span>
            </td>
            <td class="grid-edge" width="{{chart.edge_width}}" {{^grid_row.first?}}height="{{chart.grid_cell_height}}" {{/grid_row.first?}}style="border-bottom: 1px {{#grid_row.last?}}solid{{/grid_row.last?}}{{^grid_row.last?}}dashed{{/grid_row.last?}} #cccccc"></td>
            {{#grid_row.grid_cells}}
              {{#grid_cell.bar_gap?}}
                <td class="grid-bar-gap" width="{{chart.bar_gap_width}}" {{^grid_row.first?}}height="{{chart.grid_cell_height}}" {{/grid_row.first?}}style="border-bottom: 1px {{#grid_row.last?}}solid{{/grid_row.last?}}{{^grid_row.last?}}dashed{{/grid_row.last?}} #cccccc"></td>
              {{/grid_cell.bar_gap?}}
              {{#grid_cell.series_gap?}}
                <td class="grid-series-gap" width="{{chart.series_gap_width}}" {{^grid_row.first?}}height="{{chart.grid_cell_height}}" {{/grid_row.first?}}style="border-bottom: 1px {{#grid_row.last?}}solid{{/grid_row.last?}}{{^grid_row.last?}}dashed{{/grid_row.last?}} #cccccc"></td>
              {{/grid_cell.series_gap?}}
              {{#grid_cell.empty_bar?}}
                <td class="grid-empty-bar" width="{{chart.bar_width}}" {{^grid_row.first?}}height="{{chart.grid_cell_height}}" {{/grid_row.first?}}style="border-bottom: 1px {{#grid_row.last?}}solid{{/grid_row.last?}}{{^grid_row.last?}}dashed{{/grid_row.last?}} #cccccc"></td>
              {{/grid_cell.empty_bar?}}
              {{#grid_cell.bar?}}
                <td class="grid-bar" width="{{chart.bar_width}}" {{^grid_row.first?}}height="{{chart.grid_cell_height}}" {{/grid_row.first?}}style="border-bottom: 1px solid {{#grid_row.last?}}#cccccc{{/grid_row.last?}}{{^grid_row.last?}}{{grid_cell.bar_color}}{{/grid_row.last?}}" valign="bottom">
                  <table class="bar" border="0" cellpadding="0" cellspacing="0" frame="false" bgcolor="{{grid_cell.bar_color}}" width="{{chart.bar_width}}" style="border-collapse: collapse">
                    <tbody>
                      <tr>
                        <td width="{{chart.bar_width}}" height="{{grid_cell.bar_height}}"></td>
                      </tr>
                    </tbody>
                  </table>
                </td>
              {{/grid_cell.bar?}}
            {{/grid_row.grid_cells}}
            <td class="grid-edge" width="{{chart.edge_width}}" {{^grid_row.first?}}height="{{chart.grid_cell_height}}" {{/grid_row.first?}}style="border-bottom: 1px {{#grid_row.last?}}solid{{/grid_row.last?}}{{^grid_row.last?}}dashed{{/grid_row.last?}} #cccccc"></td>
          </tr>
        {{/chart.grid_rows}}
        <tr class="x-axis-row">
          <td class="axes-corner" width="{{chart.y_axis_label_width}}" height="{{chart.x_axis_height}}"></td>
          <td class="x-axis-edge" width="{{chart.edge_width}}" height="{{chart.x_axis_height}}"></td>
          {{#chart.x_axis_cells}}
            {{#x_axis_cell.series_gap?}}
              <td class="x-axis-series-gap" width="{{chart.series_gap_width}}" height="{{chart.x_axis_height}}"></td>
            {{/x_axis_cell.series_gap?}}
            {{#x_axis_cell.series_label?}}
              <td class="x-axis-series-label" height="{{chart.x_axis_height}}" colspan="{{x_axis_cell.colspan}}">
                <table class="series" width="{{x_axis_cell.width}}" border="0" cellpadding="0" cellspacing="0" frame="false" bgcolor="#ffffff" style="border-collapse: collapse">
                  <tbody>
                    <tr>
                      <td class="series-indicator" width="50%" height="{{chart.series_indicator_height}}" style="border-right: 1px solid #cccccc"></td>
                      <td class="series-indicator" width="50%" height="{{chart.series_indicator_height}}"></td>
                    </tr>
                    <tr>
                      <td class="series-label" height="{{chart.x_axis_label_height}}" colspan="2" align="center" style="font: 12px 'Open Sans', Arial, Helvetica, sans-serif; color: #494d52">{{x_axis_cell.label}}</td>
                    </tr>
                  </tbody>
                </table>
              </td>
            {{/x_axis_cell.series_label?}}
          {{/chart.x_axis_cells}}
          <td class="x-axis-edge" width="{{chart.edge_width}}" height="{{chart.x_axis_height}}"></td>
        </tr>
      </tbody>
    </table>
    """
  end
end
