# esi-objects

A library for simple and efficient upserting of inmation objects

## Changes

version | date | description
------- | ---- | -----------
1 | 2018-04-17 | Initial release

## Available functions

### INFO

This is a mandatory function for every ESI library.

### UPSERTOBJECT

Upserts an object with minimal required count of commits.

```lua
local properties =
{
  [".ObjectName"] = "testfolder",
  [".ObjectDescription"] = "testdesc",
  Custom =
  {
    ["customkey"] = "customvalue",
    ["customkey1"] = "customvalue1"
  }
}

local o, changed = O:UPSERTOBJECT({path=inmation.getself():parent():path(), 
    class = "MODEL_CLASS_GENFOLDER", 
    properties = properties})
```

Chart Example:

```lua
local prop = 
{
  [".ObjectName"] = "testchartname",
  [".ObjectDescription"] = "testdesc",
  [".ChartType"] = 	inmation.model.codes.SelectorChartType.CHART_PARETO,
  [".ParetoChart.KPIYAxisLabel"] = "Signal Contribution [%]", 
  [".ParetoChart.KPIXAxisLabel"] = "xlabel", 
  [".ParetoChart.KPIBarSettings.KPIBar"] = {h1:path(), h2:path()}, 
  [".ParetoChart.KPIBarSettings.AggregateSelection"] = {inmation.model.codes.Aggregates.AGG_TYPE_BESTFIT, inmation.model.codes.Aggregates.AGG_TYPE_BESTFIT}, 
  [".ParetoChart.KPIBarSettings.KPIBarName"] = {"test1", "test2"}, 
  [".ParetoChart.KPIBarSettings.KPIBarColor"] = {inmation.model.codes.KPIColors.RED, inmation.model.codes.KPIColors.RED}, 
  [".ParetoChart.KPIBarSettings.KPIBarOffset"] = {" ", " "},
  Custom =
  {
    ["customkey"] = "customvalue",
    ["customkey1"] = "customvalue1"
  }
}

local o, changed = O:UPSERTOBJECT
{path="/BASF/Predictive Maintenance Test", 
    class = "MODEL_CLASS_CHART", 
    properties=prop}
```


```lua
local properties =
{
  [".ObjectName"] = "testchartname1",
  [".ObjectDescription"] = "testdesc",
  [".ChartType"] = 	inmation.model.codes.SelectorChartType.CHART_TREND,
  [".TrendChart.KPITrendScale"] = inmation.model.codes.KPITrendScale.SINGLESCALE,
  [".TrendChart.TrendYAxis"] = inmation.model.codes.TrendYAxis.AUTOSCALE, --PENMINANDMAXYAXIS
  [".TrendChart.KPIYAxisLabel"] = "°C",
  [".TrendChart.KPIPenSettings.KPIPen"] = {h1:path(), h2:path()},
  [".TrendChart.KPIPenSettings.AggregateSelection"] = {inmation.model.codes.Aggregates.AGG_TYPE_BESTFIT, inmation.model.codes.Aggregates.AGG_TYPE_BESTFIT},
  [".TrendChart.KPIPenSettings.KPIPenOffset"] = {" ", " "},
  [".TrendChart.KPIPenSettings.KPIPenColor"] = {inmation.model.codes.KPIColors.RED, inmation.model.codes.KPIColors.RED},
  [".TrendChart.KPIPenSettings.KPIPenName"] = {"test1", "test2"},
  [".TrendChart.KPIPenSettings.KPIPenMinYAxis"] = {0, 100},
  [".TrendChart.KPIPenSettings.KPIPenMaxYAxis"] = {0, 100},
  [".TrendChart.KPIPenSettings.KPIPenTrendType"] = {inmation.model.codes.KPIPenTrendType.INTERPOLATED, 	inmation.model.codes.KPIPenTrendType.INTERPOLATED}
  Custom =
  {
    ["customkey"] = "customvalue",
    ["customkey1"] = "customvalue1"
  }
}
local o, changed = O:UPSERTOBJECT
  {path="/BASF/Predictive Maintenance Test",
  class = "MODEL_CLASS_CHART",
  properties=prop}
```

```lua
local properties =
{
  [".ObjectName"] = "testchartname1",
  [".ObjectDescription"] = "testdesc",
  [".ChartType"] = 	inmation.model.codes.SelectorChartType.CHART_XYPLOT,
  [".XYPlotChart.KPIStartTime"] = "*-3d",
  [".XYPlotChart.KPIEndTime"] = "*",
  [".XYPlotChart.KPIXAxisLabel"] = "X",
  [".XYPlotChart.KPIYAxisLabel"] = "Y",
  [".XYPlotChart.KPIPlotYAxis"] = inmation.model.codes.TrendYAxis.AUTOSCALE,
  [".XYPlotChart.KPIMinYAxis"] = 0,
  [".XYPlotChart.KPIMaxYAxis"] = 10,
  [".XYPlotChart.KPIXYPlotPenSettings.PenX"] = {h1:path()},
  [".XYPlotChart.KPIXYPlotPenSettings.AggregateSelectionX"] = {inmation.model.codes.Aggregates.AGG_TYPE_BESTFIT},
  [".XYPlotChart.KPIXYPlotPenSettings.PenY"] = {h1:path()},
  [".XYPlotChart.KPIXYPlotPenSettings.AggregateSelectionY"] = {inmation.model.codes.Aggregates.AGG_TYPE_BESTFIT},
  [".XYPlotChart.KPIXYPlotPenSettings.KPIPenColor"] = {inmation.model.codes.KPIColors.RED},
  [".XYPlotChart.KPIXYPlotPenSettings.KPIPenName"] = {"testpen"},
  [".XYPlotChart.KPIXYPlotPenSettings.PenIsTimeSeries"] = {true},
  [".XYPlotChart.KPIXYPlotPenSettings.PenPlotContents"] =  {inmation.model.codes.KPIPlotContent.YDATA},
  [".XYPlotChart.KPIXYPlotPenSettings.PenYDataLineType"] =	{inmation.model.codes.KPIDataLineType.SYMBOL}
  Custom =
  {
    ["customkey"] = "customvalue",
    ["customkey1"] = "customvalue1"
  }
}
local o, changed = O:UPSERTOBJECT
  {path="/BASF/Predictive Maintenance Test",
  class = "MODEL_CLASS_CHART",
  properties=prop}
```

### EXISTS

Checks existence of an object

```lua
local exists, object = O:EXISTS{ path = o:path() } --path including objectname
local exists, object = O:EXISTS{ parentpath = o:parent():path(), objectname=o.ObjectName }
```

### GETCUSTOM

Gets a custom property

```lua
local val = O:GETCUSTOM{object=o, key="asd"} --returns nil if custom key does not exist
local vals, nilkeys = O:GETCUSTOM { object = o, key = {"asd1", "asd2"} }
if vals[1]~="v1" or vals[2]~="v2"  then --check nilkeys
    error("invalid values: " .. tostring(vals[1]) .. " " .. tostring(vals[2]) .. " " .. tostring(table.concat(nilkeys)))
end
```

### SETCUSTOM

Sets a custom property

```lua
modLib:SETCUSTOM{object = obj, key = "asd", value = "asd",  disallownewkeys = false}
-- key and value always have to be strings!
modLib:SETCUSTOM{object = obj, key = {"asd1", "asd2"}, value = {"v1, v2"}}
```

### SORTCUSTOM

To come...

## Breaking changes

- Not Applicable