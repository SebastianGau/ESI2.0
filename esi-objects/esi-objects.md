# esi-objects

The 'esi-objects' library provides simplified object creation based on the minimum number of required commits/setvalues. Critical properties deciding about the subobject type are automatically detected and set first. If no object property change is detected, no setvalue or commit is done, saving resources. All arguments (and their fields) are checked with respect to type-safety.

## Changes

| version | date       | description     |
| ------- | ---------- | --------------- |
| 0.1.1   | 2018-05-24 | Initial release |

## Dependencies

| library | version | inmation core library |
| ------- | ------- | --------------------- |
| dkjson  | 2.5.0     | yes                   |

## Known Issues

None (until now).

## Available functions

### UPSERTOBJECT(args)

Upserts an object with minimal required count of commits.

#### Parameters

##### args (`table`, required)

A lua table containing the following fields:

| Field | Data Type | meaning |
| ------- | ------- | --------------------- |
| path  | `string` | The path at which the object is supposed to be upserted.
| properties  | `table` | The inmation properties which are to be set/upserted. The table keys are the property names, the table values are the required property values.
| class  | `string` | The inmation MODEL_CLASS_... of the object to be upserted (https://inmation.com/wiki/index.php?title=ClassModel/en)

#### Usage

The following code snippets demonstrate the useage of the function, including custom properties. The general syntax is there compatible with what you get when rightclicking an object -> admin -> generate lua -> upsert object in inmation, with the exception of the 'class', 'operation' and 'path' field:

```lua
inmation.mass({
	{
		class = inmation.model.classes.Chart, --not supported
		operation = inmation.model.codes.MassOp.UPSERT, --not supported
		path = "/BASF/Test Functions/testtrendchart", --not supported
		ObjectName = "testtrendchart",
		ObjectDescription = "testdesc",
		["CustomOptions.CustomProperties.CustomPropertyValue"] = {
			"customvalue1",
			"customvalue",
		},
		["CustomOptions.CustomProperties.CustomPropertyName"] = {
			"customkey1",
			"customkey",
		},
		["TrendChart.KPIYAxisLabel"] = "°C",
		["TrendChart.KPIPenSettings.KPIPenTrendType"] = {
			1,
			1,
		},
		["TrendChart.KPIPenSettings.KPIPenMaxYAxis"] = {
			0,
			100,
		},
		["TrendChart.KPIPenSettings.KPIPenMinYAxis"] = {
			0,
			100,
		},
		["TrendChart.KPIPenSettings.KPIPenName"] = {
			"test1",
			"test2",
		},
		["TrendChart.KPIPenSettings.KPIPenColor"] = {
			8,
			8,
		},
		["TrendChart.KPIPenSettings.KPIPenOffset"] = {
			" ",
			" ",
		},
		["TrendChart.KPIPenSettings.AggregateSelection"] = {
			40,
			40,
		},
		["TrendChart.KPIPenSettings.KPIPen"] = {
			"/System/Core/Core Logic/Tests/New ESI Objects/holder1",
			"/System/Core/Core Logic/Tests/New ESI Objects/thisnamewaschanged1527183733456",
		},
		["TrendChart.VisualKPIObject"] = "Trend"
	}
})
```

Upserting a folder:
```lua
local properties =
{
  ObjectName = "testfolder", --both syntaxes are allowed for propertes which to not contain dots
  [".ObjectDescription"] = "testdesc",
  Custom =
  {
    ["customkey"] = "customvalue",
    ["customkey1"] = "customvalue1"
  }
}

local o, changed = O:UPSERTOBJECT(
  {path=inmation.getself():parent():path(), 
    class = "MODEL_CLASS_GENFOLDER", 
    properties = properties})
```

Chart creation examples:
```lua
--test a pareto chart creation
local prop = 
{
  [".ObjectName"] = "testparetochart",
  [".ObjectDescription"] = "testdesc",
  [".ChartType"] = inmation.model.codes.SelectorChartType.CHART_PARETO, -- paretochart
  [".ParetoChart.KPIYAxisLabel"] = "Signal Contribution [%]", 
  [".ParetoChart.KPIXAxisLabel"] = "xlabel", 
  [".ParetoChart.KPIBarSettings.KPIBar"] = {h1:path(), h2:path()}, 
  [".ParetoChart.KPIBarSettings.AggregateSelection"] = {40, 40}, 
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
{
    path = "/BASF/Test Functions", 
    class = "MODEL_CLASS_CHART", 
    properties=prop
}


--test a xy chart creation
local properties =
{
  [".ObjectName"] = "testxychart",
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
  [".XYPlotChart.KPIXYPlotPenSettings.PenY"] = {h2:path()},
  [".XYPlotChart.KPIXYPlotPenSettings.AggregateSelectionY"] = {inmation.model.codes.Aggregates.AGG_TYPE_BESTFIT},
  [".XYPlotChart.KPIXYPlotPenSettings.KPIPenColor"] = {inmation.model.codes.KPIColors.RED},
  [".XYPlotChart.KPIXYPlotPenSettings.KPIPenName"] = {"testpen"},
  [".XYPlotChart.KPIXYPlotPenSettings.PenIsTimeSeries"] = {true},
  [".XYPlotChart.KPIXYPlotPenSettings.PenPlotContents"] =  {inmation.model.codes.KPIPlotContent.YDATA},
  [".XYPlotChart.KPIXYPlotPenSettings.PenYDataLineType"] =	{inmation.model.codes.KPIDataLineType.SYMBOL},
  Custom =
  {
    ["customkey"] = "customvalue",
    ["customkey1"] = "customvalue1"
  }
}
local o, changed = O:UPSERTOBJECT{
    path = "/BASF/Test Functions",
    class = "MODEL_CLASS_CHART",
    properties = prop
}

--test trend chart creation
local properties =
{
  [".ObjectName"] = "testtrendchart",
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
  [".TrendChart.KPIPenSettings.KPIPenTrendType"] = {inmation.model.codes.KPIPenTrendType.INTERPOLATED, 	inmation.model.codes.KPIPenTrendType.INTERPOLATED},
  Custom =
  {
    ["customkey"] = "customvalue",
    ["customkey1"] = "customvalue1"
  }
}
local o, changed = O:UPSERTOBJECT
{
  path = "/BASF/Test Functions",
  class = "MODEL_CLASS_CHART",
  properties = prop
}
```

### EXISTS(args)

Checks existence of an inmation object.

#### Parameters

##### args (`table`, required)

A lua table containing one of the following field combinations:

| Field | Data Type | meaning |
| ------- | ------- | --------------------- |
| path  | `string` | The path at which object existence is to be checked.

| Field | Data Type | meaning |
| ------- | ------- | --------------------- |
| parentpath  | `string` | The path at which the object is supposed to be upserted.
| objectname  | `string` | The object name at the path specified whose existence is to be checked.


| Field | Data Type | meaning |
| ------- | ------- | --------------------- |
| object  | `table` | An inmation object reference (lua table) whose validity is to be checked.

#### Usage

The function returns a boolean indicating existence of the object. If it is true, the inmation object reference is returned as a second argument.
```lua
local exists, object = O:EXISTS{ path = o:path() } --path including objectname
local exists, object = O:EXISTS{ parentpath = o:parent():path(), objectname=o.ObjectName }
local exists, object = O:EXISTS{ object = o }
```

### GETCUSTOM(args)

Reads one or multiple custom properties of an object

#### Parameters

##### args (`table`, required)

The following example demonstrates all possible useage combinations of this function:

Possibility 1: Read only one key. The args table has the following structure:

| Field | Data Type | meaning |
| ------- | ------- | --------------------- |
| object  | `table` | An inmation object reference (lua table)
| key     | `string`| The custom key whose value is to be read

Example:

```lua
--val is nil if custom key 'asd' does not exist or has no value
local val = O:GETCUSTOM{ object = o, key = "asd"} 
```

Possibility 2: Read multiple keys. In this case, custom keys which could not be found are returned
as a second return argument

| Field | Data Type | meaning |
| ------- | ------- | --------------------- |
| object  | `table` | An inmation object reference (lua table)
| key    | `table`| An ordered lua table (array) holding the keys to be read

Example:

```lua
--assume the value for key 'asd1' is 'v1' and for keys 'asd2' is 'v2'
local vals, nilkeys = O:GETCUSTOM { object = o, key = {"asd1", "asd2"} }
if vals[1]~="v1" or vals[2]~="v2"  then --check nilkeys
    error("invalid values: " .. tostring(vals[1]) .. " " .. tostring(vals[2]) .. " " .. tostring(table.concat(nilkeys)))
end
```

The first return argument is a ordered lua table/array holding the keys which were read successfully in the ordered given in the 'key' argument in the args table. The second return argument is nil if all keys could be read successfully, otherwise it is an ordered lua table containing the keys which could not be found.

#### Usage

Was demonstrated before.


### SETCUSTOM(args)

Reads one or multiple custom properties of an object

#### Parameters

##### args (`table`, required)

The following example demonstrates all possible useage combinations of this function based in the input argument table:

Possibility 1: Set only one key. The args table has the following structure:

| Field | Data Type | meaning |
| ------- | ------- | --------------------- |
| object  | `table` | An inmation object reference (lua table)
| key     | `string`| The custom key whose value is to be read
| value   | `string`| The value which is to be assigned for this key

Example:

```lua
-- key and value always have to be strings!
O:SETCUSTOM{object = obj, key = "asd", value = "asd"}
```

Possibility 2: Set multiple keys at once. In this case the args table has the following structure:

| Field | Data Type | meaning |
| ------- | ------- | --------------------- |
| object  | `table` | An inmation object reference (lua table)
| key     | `table`| The custom keys whose value is to be read as an ordered lua table.
| value     | `table`| The values which are to be assigned for this key as an ordered lua table.

Example:

```lua
O:SETCUSTOM{object = obj, key = {"asd1", "asd2"}, value = {"v1, v2"}}
```

#### Usage

Was demonstrated before.

### SORTCUSTOM

TO BE ADDED BY TIMO

#### Parameters

#### Useage

Sorts custom properties of an object. Documentation

### BREAKPATH

TO BE ADDED BY TIMO

#### Parameters

#### Useage