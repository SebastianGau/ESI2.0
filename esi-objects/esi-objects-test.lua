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



local p = json.decode('{".ObjectDescription":"desc",".OpcEngUnit":"m5",".ObjectName":"Test3",".ArchiveOptions.StorageStrategy":1,".ArchiveOptions.ArchiveSelector":2,".CustomOptions.CustomString":"TEST1"}')
local h4 = O:UPSERTOBJECT{path = cwd, class = "MODEL_CLASS_HOLDERITEM", properties = p }
local p = json.decode('{".ObjectDescription":"desc",".OpcEngUnit":"m5",".ObjectName":"Test3",".ArchiveOptions.StorageStrategy":1,".ArchiveOptions.ArchiveSelector":2,".CustomOptions.CustomString":"TEST2"}')
local h4, _, _, details = O:UPSERTOBJECT{path = cwd, class = "MODEL_CLASS_HOLDERITEM", properties = p }
if h4.CustomOptions.CustomString ~= "TEST2" then
    error("Property not set: log " .. O:GETLOG())
end


--test a chart creation
local prop = 
{
  [".ObjectName"] = "testchartname",
  [".ObjectDescription"] = "testdesc",
  [".ChartType"] = 2, -- paretochart
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
{path="/BASF", 
    class = "MODEL_CLASS_CHART", 
    properties=prop}



return "passed"