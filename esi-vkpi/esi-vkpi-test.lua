self:CONNECTDATABASE()
self:SELECTDATABASE("admin")

self:ENSUREPROFILE("TestProfile")
self:ENSUREDASHBOARDINPARENTPROFILE("TestProfile", "TestDashboard")
self:CLEARDASHBOARD("TestDashboard")

local groupobj = inmation.getobject("/BASF/Predictive Maintenance/EMEA/Ludwigshafen/Steamcracker (Prediction)/A100/W100A")
local kpiobj = inmation.getobject("/BASF/Predictive Maintenance/EMEA/Ludwigshafen/Steamcracker (Prediction)/A100/W100A/T_out Trend W100A")
local trendobj = inmation.getobject("/BASF/Predictive Maintenance/EMEA/Ludwigshafen/Steamcracker (Prediction)/A100/W100A/days_online")


--add an embedded content
--(DashboardName, Contentname, ContentURL, {width = 4, height = 8})
--works after next caching
self:ADDWIDGETTODASHBOARD("TestDashboard", "TestContentName", "www.google.com")

--add a dashboard link to the dashboard "TestDashboard" linking to the default dashboard
--(TargetDashboardName, LinkedDashboardName, {width = 4, height = 8})
self:ADDWIDGETTODASHBOARD("TestDashboard", "Default");

--add a dashboard link widget to the dashbord "default" pointing to the dashboard "TestDashboard"
self:CLEARDASHBOARD("Default")
self:ADDWIDGETTODASHBOARD("Default", "TestDashboard"); --does not work since default dashboard was n

--add a group block to the dashboard with name "TestDashboard"
self:ADDWIDGETTODASHBOARD("TestDashboard", groupobj, {howto = "GroupBlock", width = 1})

--adds a bookmark to the profile with name "TestProfile" to the Dashboard with name "Default"
self:ENSUREBOOKMARK("TestProfile", "Default")
--adds a bookmark to the profile with name "Default" to the Dashboard with name "TestDashboard"
self:ENSUREBOOKMARK("Default", "TestDashboard")
--adds a bookmark to the dashboard "TestDashboard" for all profiles
self:ENSUREBOOKMARKFORALLPROFILES("TestDashboard")


--different mapping options for group-like inmation objects
self:ADDWIDGETTODASHBOARD("TestDashboard", groupobj, {howto = "GroupBlock", width = 2})
self:ADDWIDGETTODASHBOARD("TestDashboard", groupobj, {howto = "KPIMap", width = 4})
self:ADDWIDGETTODASHBOARD("TestDashboard", groupobj, {howto = "KPIMapGroup", width = 4})
self:ADDWIDGETTODASHBOARD("TestDashboard", groupobj, {howto = "KPIMapStatus", width = 4})

self:ADDWIDGETTODASHBOARD("TestDashboard", groupobj, {howto = "ChartList", width = 4})
self:ADDWIDGETTODASHBOARD("TestDashboard", groupobj, {howto = "ChartListChartType", width = 4})
self:ADDWIDGETTODASHBOARD("TestDashboard", groupobj, {howto = "ChartListGroup", width = 4})

self:ADDWIDGETTODASHBOARD("TestDashboard", groupobj, {howto = "KPIBullet", width = 4})
self:ADDWIDGETTODASHBOARD("TestDashboard", groupobj, {howto = "KPIBulletGroup", width = 4})
self:ADDWIDGETTODASHBOARD("TestDashboard", groupobj, {howto = "KPIBulletStatus", width = 4})

self:ADDWIDGETTODASHBOARD("TestDashboard", groupobj, {howto = "KPISummaryHistory", width=2})
self:ADDWIDGETTODASHBOARD("TestDashboard", groupobj, {howto = "KPIStatusHistory", width=2})

--different mapping options for inmation kpi objects from the kpimodel
self:ADDWIDGETTODASHBOARD("TestDashboard", kpiobj, {howto = "KPIBlock"})
self:ADDWIDGETTODASHBOARD("TestDashboard", kpiobj, {howto = "KPITrend", width=2})

--mapping options for inmation chart objects from the kpimodel
self:ADDWIDGETTODASHBOARD("TestDashboard", trendobj, {width=4})

--test invalid width
local ok, err = pcall(function() self:ADDWIDGETTODASHBOARD("TestProfile", kpiobj, {howto = "KPIBlock", width = 3}) end)
if ok then error("An error should have been raised!") end


--test the homegroup
self.ADG:ADDWIDGETTODASHBOARD("TestDashboard", inmation.getobject("/BASF"), {howto="GroupList", homegroup=true})


--test deleting etc
self:ENSUREPROFILE("TestProfile2")
self:ENSUREDASHBOARDINPARENTPROFILE("TestProfile2", "TestDashboard2")
local a = self:GETDASHBOARDSINPROFILE("TestProfile2")
if #a==0 then
    error("")
end
if a[1].name~="TestDashboard2" then
    error("dbs in testprofile 2: " .. table.concat(a, " "))
end
self:DELETEPROFILE("TestProfile2")
if self:_dashboardExists("TestDashboard2") then
    error("The dashboard should have been deleted!")
end

self:DISCONNECTDATABASE()

do return "passed" end
