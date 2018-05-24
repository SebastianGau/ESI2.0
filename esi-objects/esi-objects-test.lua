--<ObjectVersion>109</ObjectVersion>
local O = require 'esi-objects'
local json = require "dkjson"

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

local exists, object = O:EXISTS{path=o:path()}
local exists, object = O:EXISTS{parentpath=o:parent():path(), objectname=o.ObjectName}
local exists, object = O:EXISTS{object=0}


O:SETCUSTOM{object = o, key = "asd", value = "v"}
O:SETCUSTOM{object = o, key = {"asd1", "asd2"}, value = {"v1", "v2"}}


local val = O:GETCUSTOM{object=o, key="asd"} --returns nil if custom key does not exist
if val~="v" then
    error("invalid value: " .. tostring(val))
end
local vals, nilkeys = O:GETCUSTOM{object=o, key={"asd1", "asd2"}}
if vals[1]~="v1" or vals[2]~="v2"  then --check nilkeys
    error("invalid values: " .. tostring(vals[1]) .. " " .. tostring(vals[2]) .. " " .. tostring(table.concat(nilkeys)))
end 
--returns ordered table with the correspoding values

--validity is also checked with the EXISTS command
local valid = O:EXISTS{object = o}
if not valid then
    error("The object should be a valid inmation object!")
end


local cwd = inmation.getself():parent():path()

local h1 = O:UPSERTOBJECT{path = cwd, class = "MODEL_CLASS_HOLDERITEM", properties =  {
    [".ObjectName"] = "holder1"}
}

local h2 = O:UPSERTOBJECT{path = cwd, class = "MODEL_CLASS_HOLDERITEM", properties =  {
    [".ObjectName"] = "holder2",
    [".CustomOptions.CustomString"] = "asd"}
}

--test special properties
if h2.CustomOptions.CustomString ~= "asd" then
    error("Property was not upserted correctly! log " .. O:GETLOG())
end
local h3 = O:UPSERTOBJECT{path = cwd, class = "MODEL_CLASS_HOLDERITEM", properties =  {
    [".ObjectName"] = "holder2",
    [".CustomOptions.CustomString"] = "asd1"}
}
if h3.CustomOptions.CustomString ~= "asd1" then
    error("Property was not upserted correctly! log " .. O:GETLOG())
end

--test name changes (you have to pass numid for this to work...)
local new = "thisnamewaschanged" .. inmation.now()
local testh = O:UPSERTOBJECT{path = cwd, class = "MODEL_CLASS_HOLDERITEM", numid = h3:numid(), properties =  {
    [".ObjectName"] = new,
    [".CustomOptions.CustomString"] = "asd1"}
}
if testh.ObjectName ~= new or testh:numid() ~= h3:numid() then
    error("Name change did not succeed!")
end


local p = json.decode('{".ObjectDescription":"desc",".OpcEngUnit":"m5",".ObjectName":"Test3",".ArchiveOptions.StorageStrategy":1,".ArchiveOptions.ArchiveSelector":2,".CustomOptions.CustomString":"TEST1"}')
local h4 = O:UPSERTOBJECT{path = cwd, class = "MODEL_CLASS_HOLDERITEM", properties = p }
local p = json.decode('{".ObjectDescription":"desc",".OpcEngUnit":"m5",".ObjectName":"Test3",".ArchiveOptions.StorageStrategy":1,".ArchiveOptions.ArchiveSelector":2,".CustomOptions.CustomString":"TEST2"}')
local h4, _, _, details = O:UPSERTOBJECT{path = cwd, class = "MODEL_CLASS_HOLDERITEM", properties = p }
if h4.CustomOptions.CustomString ~= "TEST2" then
    error("Property not set: log " .. O:GETLOG())
end


--test a pareto chart creation
local props = 
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
    properties = props
}


--test a xy chart creation
local props =
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
    properties = props
}

--test trend chart creation
local props =
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
  properties = props
}



return "passed"