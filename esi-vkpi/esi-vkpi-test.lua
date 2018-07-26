local VKPI = require 'esi-vkpi'
local JSON = require 'dkjson'

VKPI:CONNECTDATABASE("vkpi", {dsn = "VKPI", user = "sa", password = "..."})
--first argument is just a name for internal connection name
VKPI:SELECTDATABASE("visualkpiuser") --visualkpiqa, visualkpi

VKPI:CLEARCURRENTDATABASE()

VKPI:DELETEPROFILE("TestProfile")
VKPI:ENSUREPROFILE("TestProfile")
VKPI:ENSUREDASHBOARDINPARENTPROFILE("TestProfile", "TestDashboard")
VKPI:CLEARDASHBOARD("TestDashboard")

local groupobj = inmation.getobject("/BASF/Predictive Maintenance/EMEA/Ludwigshafen/Steamcracker (Prediction)/A100/W100A")
local kpiobj = inmation.getobject("/BASF/Predictive Maintenance/EMEA/Ludwigshafen/Steamcracker (Prediction)/A100/W100A/T_out Trend W100A")
local trendobj = inmation.getobject("/BASF/Predictive Maintenance/EMEA/Ludwigshafen/Steamcracker (Prediction)/A100/W100A/days_online")


--add an embedded content
--(DashboardName, Contentname, ContentURL, {width = 4, height = 8})
--works after next caching
VKPI:ADDWIDGETTODASHBOARD("TestDashboard", "TestContentName", "http://www.google.com")

--add a dashboard link to the dashboard "TestDashboard" linking to the "Default" dashboard
--(TargetDashboardName, LinkedDashboardName, {width = 4, height = 8})
VKPI:ADDWIDGETTODASHBOARD("TestDashboard", "Default");

--add a dashboard link widget to the dashbord "default" pointing to the dashboard "TestDashboard"
VKPI:CLEARDASHBOARD("Default")
VKPI:ADDWIDGETTODASHBOARD("Default", "TestDashboard"); 

--add a group block to the dashboard with name "TestDashboard"
VKPI:ADDWIDGETTODASHBOARD("TestDashboard", groupobj, {howto = "GroupBlock", width = 1})

--adds a bookmark to the profile with name "TestProfile" to the Dashboard with name "Default"
VKPI:ENSUREBOOKMARK("TestProfile", "Default")
--adds a bookmark to the profile with name "Default" to the Dashboard with name "TestDashboard"
VKPI:ENSUREBOOKMARK("Default", "TestDashboard")
--adds a bookmark to the dashboard "TestDashboard" for all profiles
VKPI:ENSUREBOOKMARKFORALLPROFILES("TestDashboard")


--different mapping options for group-like inmation objects
VKPI:ADDWIDGETTODASHBOARD("TestDashboard", groupobj, {howto = "GroupBlock", width = 2})
VKPI:ADDWIDGETTODASHBOARD("TestDashboard", groupobj, {howto = "KPIMap", width = 4})
VKPI:ADDWIDGETTODASHBOARD("TestDashboard", groupobj, {howto = "KPIMapGroup", width = 4})
VKPI:ADDWIDGETTODASHBOARD("TestDashboard", groupobj, {howto = "KPIMapStatus", width = 4})

VKPI:ADDWIDGETTODASHBOARD("TestDashboard", groupobj, {howto = "ChartList", width = 4})
VKPI:ADDWIDGETTODASHBOARD("TestDashboard", groupobj, {howto = "ChartListChartType", width = 4})
VKPI:ADDWIDGETTODASHBOARD("TestDashboard", groupobj, {howto = "ChartListGroup", width = 4})

VKPI:ADDWIDGETTODASHBOARD("TestDashboard", groupobj, {howto = "KPIBullet", width = 4})
VKPI:ADDWIDGETTODASHBOARD("TestDashboard", groupobj, {howto = "KPIBulletGroup", width = 4})
VKPI:ADDWIDGETTODASHBOARD("TestDashboard", groupobj, {howto = "KPIBulletStatus", width = 4})

VKPI:ADDWIDGETTODASHBOARD("TestDashboard", groupobj, {howto = "KPISummaryHistory", width=2})
VKPI:ADDWIDGETTODASHBOARD("TestDashboard", groupobj, {howto = "KPIStatusHistory", width=2})

--different mapping options for inmation kpi objects from the kpimodel
VKPI:ADDWIDGETTODASHBOARD("TestDashboard", kpiobj, {howto = "KPIBlock"})
VKPI:ADDWIDGETTODASHBOARD("TestDashboard", kpiobj, {howto = "KPITrend", width=2})

--mapping options for inmation chart objects from the kpimodel
VKPI:ADDWIDGETTODASHBOARD("TestDashboard", trendobj, {width=4})

--test invalid width 
local ok, err = pcall(function() VKPI:ADDWIDGETTODASHBOARD("TestProfile", kpiobj, {howto = "KPIBlock", width = 3}) end)
if ok then error("An error should have been raised!") end


--test the homegroup
VKPI:ADDWIDGETTODASHBOARD("TestDashboard", inmation.getobject("/BASF/Predictive Maintenance"), {howto="GroupList", homegroup=true})


--test deleting etc
VKPI:ENSUREPROFILE("TestProfile2")
VKPI:ENSUREDASHBOARDINPARENTPROFILE("TestProfile2", "TestDashboard2")
local a = VKPI:GETDASHBOARDSINPROFILE("TestProfile2")
if #a==0 then
    local s = VKPI.DB:GETSTATISTICS()
    error(JSON.encode(s))
end
if a[1].name ~= "TestDashboard2" then
    error("dbs in testprofile 2: " .. table.concat(a, " "))
end
VKPI:DELETEPROFILE("TestProfile2")
if VKPI:_dashboardExists("TestDashboard2") then
    error("The dashboard should have been deleted!")
end

VKPI:DISCONNECTDATABASE()


do return "passed" end
