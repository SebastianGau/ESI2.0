--esi-vkpi
local ODBC = require 'esi-odbc'



--this is just a class needed by BASF.DashboardGeneration
local GridPlacer = 
{
  Placements,
  height = 300,
  width = 4,
}

function GridPlacer:initPlacements()
  local Placements = {}
  for i=1, self.height do
    Placements[i] = {false, false, false, false}
  end
  return Placements
end

function GridPlacer:new(o)
  o = o or {}
  self.__index = self
  setmetatable(o, self)
  --table fields require this extra initialization
  o.Placements = self:initPlacements() 
  return o
end

function GridPlacer:isCellFree(x, y)
  if self.Placements[x][y] == false then
    return true
  elseif self.Placements[x][y] == true then
    return false
  else
    error("out of bounds! x: " .. x .. " y: " .. y)
  end
end

function GridPlacer:occupyCell(x, y)
  if self:isCellFree(x, y) then
    self.Placements[x][y] = true
  else
    error("cell already occupied! x: " .. x .. " y: " .. y)
  end
end

function GridPlacer:occupyArea(rowstart, height, colstart, width)
  if not self:isAreaFree(rowstart, height, colstart, width) then
    error("The object cannot be placed here! rowstart, height, colstart, width: " .. rowstart .. " " .. height.. " " ..colstart.. " " ..width)
  end
  for x=rowstart, (rowstart+height-1) do
    for y=colstart, (colstart+width-1) do
      --if self:isCellFree(x, y) then
      self:occupyCell(x, y)
      --end
    end
  end
end

function GridPlacer:isAreaFree(rowstart, height, colstart, width)
  for x=rowstart, (rowstart+height-1) do
    for y=colstart, (colstart+width-1) do
      if y > self.width or not self:isCellFree(x, y) then
        return false
      end
    end
  end
  return true
end

function GridPlacer:findPlacementSpot(height, width)
  if width > self.width then
    error("Objects with width " .. width .. "cannot be placed on this grid!")
  end
  for x=1, self.height do
    for y=1, 4 do
      if self:isAreaFree(x, height, y, width) then
        return x, y
      end
    end
  end
  --returns rowstart, colstart, rowend, colend
end

function GridPlacer:placeObject(self, height, width)
  local rowstart, colstart = self:findPlacementSpot(height, width)
  self:occupyArea(rowstart, height, colstart, width)
  local rowend = rowstart + height - 1
  local colend = colstart + width - 1
  return rowstart, rowend, colstart, colend
end



--maps from the {howto="TrendChart"} argument to the entries in the tableWidgets in the VKPI database
local VKPIMappingTable =
{
  TrendChart = { 
    MetaDescription = "Trend",
    ObjectType = 3,
    WidgetType = 1,
    URIWithoutID = "?pid=70&trend=",
    PossibleWidhts = {["2"] = true, ["4"] = true},
    StandardWidth = 4,
    PossibleHeights = {["4"] = true, ["8"] = true, ["12"] = true},
    StandardHeight = 4
  },
  KPIBlock = { 
    MetaDescription = "KPI Block",
    ObjectType = 2,
    WidgetType = 2,
    URIWithoutID = "?pid=70&kpi=",
    PossibleWidhts = {["1"] = true, ["2"] = true},
    StandardWidth = 2,
    PossibleHeights = {["1"] = true, ["2"] = true},
    StandardHeight = 1
  },
  KPITrend = { --a KPI shown as a trend on the dashboard
    MetaDescription = "Trend",
    ObjectType = 2,
    WidgetType = 1,
    URIWithoutID = "?pid=70&kpi=",
    PossibleWidhts = {["2"] = true, ["4"] = true},
    StandardWidth = 4,
    PossibleHeights = {["4"] = true, ["8"] = true, ["12"] = true},
    StandardHeight = 4
  },
  ParetoChart = { 
    MetaDescription = "Pareto Chart",
    ObjectType = 9,
    WidgetType = 1,
    URIWithoutID = "?pid=400&charttime=*&pcid=",
    PossibleWidhts = {["2"] = true, ["4"] = true},
    StandardWidth = 4,
    PossibleHeights = {["4"] = true, ["8"] = true, ["12"] = true},
    StandardHeight = 4
  },
  GroupList = {
    MetaDescription = "Group List",
    ObjectType = 1,
    WidgetType = 1,
    URIWithoutID = "?pid=10&gv=0&gx=0&gid=",
    PossibleWidhts = {["2"] = true, ["4"] = true},
    StandardWidth = 4,
    PossibleHeights = {["4"] = true, ["8"] = true, ["12"] = true},
    StandardHeight = 4
  },
  GroupListExpanded = {
    MetaDescription = "Group List",
    ObjectType = 1,
    WidgetType = 1,
    URIWithoutID = "?pid=10&gv=0&gx=1&gid=",
    PossibleWidhts = {["2"] = true, ["4"] = true},
    StandardWidth = 4,
    PossibleHeights = {["4"] = true, ["8"] = true, ["12"] = true},
    StandardHeight = 4
  },
  ChartList = {
    MetaDescription = "Chart List",
    ObjectType = 1,
    WidgetType = 1,
    URIWithoutID = "?pid=30&tv=0&tx=1&gid=", 
    PossibleWidhts = {["2"] = true, ["4"] = true},
    StandardWidth = 4,
    PossibleHeights = {["4"] = true, ["8"] = true, ["12"] = true},
    StandardHeight = 4
  },
  ChartListChartType = {
    MetaDescription = "Chart List",
    ObjectType = 1,
    WidgetType = 1,
    URIWithoutID = "?pid=30&group=ct&tv=0&tx=1&gid=",
    PossibleWidhts = {["2"] = true, ["4"] = true},
    StandardWidth = 4,
    PossibleHeights = {["4"] = true, ["8"] = true, ["12"] = true},
    StandardHeight = 4
  },
  ChartListGroup = {
    MetaDescription = "Chart List",
    ObjectType = 1,
    WidgetType = 1,
    URIWithoutID = "?pid=30&group=gr&tv=0&tx=1&gid=",
    PossibleWidhts = {["2"] = true, ["4"] = true},
    StandardWidth = 4,
    PossibleHeights = {["4"] = true, ["8"] = true, ["12"] = true},
    StandardHeight = 4
  },
  KPIMap = {
    MetaDescription = "KPI Map",
    ObjectType = 1,
    WidgetType = 1,
    URIWithoutID = "?pid=20&kv=2&kx=1&gid=", 
    PossibleWidhts = {["2"] = true, ["4"] = true},
    StandardWidth = 4,
    PossibleHeights = {["4"] = true, ["8"] = true, ["12"] = true},
    StandardHeight = 4
  },
  KPIMapGroup = {
    MetaDescription = "KPI Map",
    ObjectType = 1,
    WidgetType = 1,
    URIWithoutID = "?pid=20&kv=2&kx=1&group=gr&gid=", 
    PossibleWidhts = {["2"] = true, ["4"] = true},
    StandardWidth = 4,
    PossibleHeights = {["4"] = true, ["8"] = true, ["12"] = true},
    StandardHeight = 4
  },
  KPIMapGroupFilterGood = {
    MetaDescription = "KPI Map",
    ObjectType = 1,
    WidgetType = 1,
    URIWithoutID = "?pid=20&kv=2&kx=1&group=gr&filter=g&gid=", 
    PossibleWidhts = {["2"] = true, ["4"] = true},
    StandardWidth = 4,
    PossibleHeights = {["4"] = true, ["8"] = true, ["12"] = true},
    StandardHeight = 4
  },
  KPIMapGroupFilterOutGoodAndNotInService = {
    MetaDescription = "KPI Map",
    ObjectType = 1,
    WidgetType = 1,
    URIWithoutID = "?pid=20&kv=2&kx=1&group=gr&filter=g%3Anis&gid=", 
    PossibleWidhts = {["2"] = true, ["4"] = true},
    StandardWidth = 4,
    PossibleHeights = {["4"] = true, ["8"] = true, ["12"] = true},
    StandardHeight = 4
  },
  KPIMapGroupFilterGoodAndLows = {
    MetaDescription = "KPI Map",
    ObjectType = 1,
    WidgetType = 1,
    URIWithoutID = "?pid=20&kv=2&kx=1&group=gr&filter=g%3Al%3All%3Alll%3Au%3Ana&gid=", 
    PossibleWidhts = {["2"] = true, ["4"] = true},
    StandardWidth = 4,
    PossibleHeights = {["4"] = true, ["8"] = true, ["12"] = true},
    StandardHeight = 4
  },
  KPIMapGroupOnlyGood = {
    MetaDescription = "KPI Map",
    ObjectType = 1,
    WidgetType = 1,
    URIWithoutID = "?pid=20&kv=2&kx=1&group=gr&filter=hhh%3Ahh%3Ah%3Al%3All%3Alll%3Au%3Anis%3Ana&gid=",  
    PossibleWidhts = {["2"] = true, ["4"] = true},
    StandardWidth = 4,
    PossibleHeights = {["4"] = true, ["8"] = true, ["12"] = true},
    StandardHeight = 4
  },
  KPIMapGroupOnlyGoodAndNotInService = {
    MetaDescription = "KPI Map",
    ObjectType = 1,
    WidgetType = 1,
    URIWithoutID = "?pid=20&kv=2&kx=1&group=gr&filter=hhh%3Ahh%3Ah%3Al%3All%3Alll%3Au%3Ana&gid=",  
    PossibleWidhts = {["2"] = true, ["4"] = true},
    StandardWidth = 4,
    PossibleHeights = {["4"] = true, ["8"] = true, ["12"] = true},
    StandardHeight = 4
  },
  KPIMapStatus = {
    MetaDescription = "KPI Map",
    ObjectType = 1,
    WidgetType = 1,
    URIWithoutID = "?pid=20&kv=2&kx=1&group=st&gid=", 
    PossibleWidhts = {["2"] = true, ["4"] = true},
    StandardWidth = 4,
    PossibleHeights = {["4"] = true, ["8"] = true, ["12"] = true},
    StandardHeight = 4
  },
  KPIMapStatusFilterGood = {
    MetaDescription = "KPI Map",
    ObjectType = 1,
    WidgetType = 1,
    URIWithoutID = "?pid=20&kv=2&kx=1&group=st&filter=g&gid=", 
    PossibleWidhts = {["2"] = true, ["4"] = true},
    StandardWidth = 4,
    PossibleHeights = {["4"] = true, ["8"] = true, ["12"] = true},
    StandardHeight = 4
  },
  KPIBullet = { --KPI List is too similar to this, therefore ommitted
    MetaDescription = "KPI Bullet",
    ObjectType = 1,
    WidgetType = 1,
    URIWithoutID = "?pid=20&kx=1&kv=1&gid=",
    PossibleWidhts = {["2"] = true, ["4"] = true},
    StandardWidth = 4,
    PossibleHeights = {["4"] = true, ["8"] = true, ["12"] = true},
    StandardHeight = 4
  },
  KPIBulletGroup = {
    MetaDescription = "KPI Bullet",
    ObjectType = 1,
    WidgetType = 1,
    URIWithoutID = "?pid=20&group=gr&kx=1&kv=1&gid=",
    PossibleWidhts = {["2"] = true, ["4"] = true},
    StandardWidth = 4,
    PossibleHeights = {["4"] = true, ["8"] = true, ["12"] = true},
    StandardHeight = 4
  },
  KPIBulletStatus = {
    MetaDescription = "KPI Bullet",
    ObjectType = 1,
    WidgetType = 1,
    URIWithoutID = "?pid=20&group=st&kx=1&kv=1&gid=",
    PossibleWidhts = {["2"] = true, ["4"] = true},
    StandardWidth = 4,
    PossibleHeights = {["4"] = true, ["8"] = true, ["12"] = true},
    StandardHeight = 4
  },
  HomeGroup = { 
    MetaDescription = "Group List",
    ObjectType = 1,
    WidgetType = 1,
    URIWithoutID = "?pid=10&gv=0&gx=0",
    PossibleWidhts = {["2"] = true, ["4"] = true},
    StandardWidth = 4,
    PossibleHeights = {["4"] = true, ["8"] = true, ["12"] = true},
    StandardHeight = 4
  },
  KPISummaryHistory = {
    MetaDescription = "KPI Summary History",
    ObjectType = 1,
    WidgetType = 1,
    URIWithoutID = "?pid=20&kx=1&pct=3&kv=7&gid=", --&fromtime=*-1 Days&totime=* 
    PossibleWidhts = {["2"] = true, ["4"] = true},
    StandardWidth = 4,
    PossibleHeights = {["4"] = true, ["8"] = true, ["12"] = true},
    StandardHeight = 4
  },
  KPIStatusHistory = {
    MetaDescription = "KPI Status History",
    ObjectType = 1,
    WidgetType = 1,
    URIWithoutID = "?pid=20&kv=6&kx=1&pct=0&gid=", --&fromtime=*-1 Days&totime=*
    PossibleWidhts = {["2"] = true, ["4"] = true},
    StandardWidth = 4,
    PossibleHeights = {["4"] = true, ["8"] = true, ["12"] = true},
    StandardHeight = 4
  },
  XYPlot = {
    MetaDescription = "XY Plot",
    ObjectType = 10,
    WidgetType = 1,
    URIWithoutID = "?pid=410&xyid=", --&fromtime=*-1 Days&totime=*
    PossibleWidhts = {["2"] = true, ["4"] = true},
    StandardWidth = 4,
    PossibleHeights = {["4"] = true, ["8"] = true, ["12"] = true},
    StandardHeight = 4
  },
  EmbeddedContent = {
    MetaDescription = "Embedded Content",
    ObjectType = 14,
    WidgetType = 1,
    URIWithoutID = "?pid=450&ecid=", --id from tableEmbeddedContents
    PossibleWidhts = {["2"] = true, ["4"] = true},
    StandardWidth = 4,
    PossibleHeights = {["4"] = true, ["8"] = true, ["12"] = true},
    StandardHeight = 4
  },
  GroupBlock = {
    MetaDescription = "Group Block",
    ObjectType = 1,
    WidgetType = 4,
    URIWithoutID = "?pid=20&kx=1&kv=2&gid=", 
    PossibleWidhts = {["1"] = true, ["2"] = true},
    StandardWidth = 2,
    PossibleHeights = {["1"] = true},
    StandardHeight = 1
  },
  DashboardLink = {
    MetaDescription = "Dashboard Link",
    ObjectType = 1,
    WidgetType = 6,
    URIWithoutID = "null", 
    PossibleWidhts = {["1"] = true, ["2"] = true},
    StandardWidth = 2,
    PossibleHeights = {["1"] = true},
    StandardHeight = 1
  }
}


-- local LockManager = 
-- {
--   LockHolderPath = '/System/Core/Core Logic/Predictive Maintenance/DashboardLockHolder',
--   socket = require 'socket',
--   MaxWaitTimeMinues = 1,

--   WaitAcquire = function(self)
--     local start = inmation.now()
--     while true do
--       local o = inmation.getobject(inmation.getvalue(self.LockHolderPath))
--       if o==nil 
--       or type(o) ~= 'table'
--       or o:path()==inmation.getselfpath() 
--       or (inmation.now() - start)/(1000*60) > self.MaxWaitTimeMinues
--       then
--         break
--       end
--       inmation.setvalue(inmation.getself():path(), "waiting for object " .. o:path() .. " to release the lock")
--       self.socket.sleep(1);
--     end
--     inmation.setvalue(self.LockHolderPath, inmation.getself():path())
--   end,

--   TryAcquire = function(self)
--     local o = inmation.getobject(inmation.getvalue(self.LockHolderPath))
--     if o == nil or type(o)~='table' or o:path()==inmation.getselfpath()   then
--       inmation.setvalue(self.LockHolderPath, inmation.getself():path())
--       return true
--     else
--       return false
--     end
--   end,

--   Release = function(self)
--     inmation.setvalue(self.LockHolderPath, nil)
--   end
-- }

local SQLQueries = 
{
    dbname = ""
}

function SQLQueries:ResetAllDefaultDashboards()
    return "UPDATE " .. dbname .. ".dbo.tableDashboards SET IsDefault = 0"
end

function SQLQueries:SetDefaultDashboard()
    return "UPDATE " .. dbname .. ".dbo.tableDashboards SET IsDefault = 1 WHERE Name = '%s'"
end

function SQLQueries:ResetAllDefaultProfiles()
    return "UPDATE " .. self.dbname .. ".dbo.tableProfiles SET IsDefault = 0"
end


function SQLQueries:SetDefaultProfile()
    return "UPDATE " .. self.dbname .. ".dbo.tableProfiles SET IsDefault = 1 WHERE Name = '%s'"
end

function SQLQueries:ClearDataBase()
    return
    "DELETE FROM " .. self.dbname .. ".dbo.tableProfiles" ..
    "DELETE FROM " .. self.dbname .. ".dbo.tableDashboards" ..
    "DELETE FROM " .. self.dbname .. ".dbo.tableWidgets" ..
    "DELETE FROM " .. self.dbname .. ".dbo.tableBookmarks" ..
    "INSERT INTO " .. self.dbname .. ".dbo.tableProfiles " ..
    [[(ID, ProfileGroupID, DisplayOrder,
    Name, Description, Locked,
    Show, IsDefault)
    VALUES ('737234DD-8238-4F5B-B482-97FB36D10029', '444E6CC9-D1DC-4669-B54C-2E5FD7760249', NULL, 
    'Default', 'System Default Profile', 0,
    1, 1)]] ..
    "INSERT INTO " .. self.dbname .. ".dbo.tableDashboards " ..
    [[(ID, GroupID, ProfileID, 
    DisplayOrder, Name, Description,
    Locked, Show, IsDefault, 
    StartTime, EndTime)
    VALUES ('D9925737-5DD7-474E-9B9D-BA307BD5A6A9', '7EE27D6E-A1CB-48CD-A073-2968AF67F477', '737234DD-8238-4F5B-B482-97FB36D10029',
    NULL, 'Default', 'System Default Dashboard', 
    0, 1, 1, 
    NULL, NULL)]]
end

function SQLQueries:ProfileExists()
    return "SELECT COUNT(Name)" ..
    "FROM " .. self.dbname .. ".dbo.tableProfiles" ..
    "WHERE (Name = '%s')"
end

function SQLQueries:GetAllProfileNames()
    return "SELECT convert(nvarchar(50), ID) as ID, Name" ..
    "FROM " .. self.dbname .. ".dbo.tableProfiles"
end

function SQLQueries:GetProfileID()
    return [[SELECT convert(nvarchar(50), ID)]] ..
    "FROM " .. self.dbname .. ".dbo.tableProfiles" ..
    "WHERE (Name  = '%s')"
end

function SQLQueries:GetProfilesByDescription() 
    return [[SELECT convert(nvarchar(50), ID) as ID, dbo.tableProfiles.Name]] .. 
    "FROM " .. self.dbname .. ".dbo.tableProfiles" ..
    "WHERE (Description  = '%s')"
end

function SQLQueries:DeleteProfile()
    return "EXECUTE " .. self.dbname .. ".dbo.usp_DeleteProfile '%s'"
end

function SQLQueries:SaveProfile()
    return "EXECUTE " .. self.dbname .. ".dbo.usp_SaveProfile '%s', null, '%s', '%s', 0, 1, 0"
end

function SQLQueries:SetProfileDescription()
    return "UPDATE " .. self.dbname .. ".dbo.tableProfiles SET Description = '%s' WHERE (Name = '%s')"
end

function SQLQueries:GetDashboardsInProfile()
    return "SELECT convert(nvarchar(50), ID) as ID, Name" ..
    "FROM " .. self.dbname .. ".dbo.tableDashboards" ..
    "WHERE (ProfileID = '%s')"
end

function SQLQueries:GetDashboardsByDescription()
    return [[SELECT      convert(nvarchar(50), ID) as ID, Name]] .. 
    "FROM " .. self.dbname .. ".dbo.tableDashboards" .. 
    [[WHERE (Description  LIKE '%%%s%%')]]
end

function SQLQueries:GetDashboardID()
    return "SELECT    convert(nvarchar(50), ID) as ID" ..
    "FROM " .. self.dbname .. ".dbo.tableDashboards" .. 
    "WHERE Name = '%s'"
end

function SQLQueries:NewDashboard()
    return "EXECUTE " .. self.dbname .. ".dbo.usp_NewDashboard '%s', '%s', '%s'"
end

function SQLQueries:UpdateDashboardDescription()
    return "UPDATE " .. self.dbname .. ".dbo.tableDashboards SET Description = '%s' WHERE (ID = '%s')"
end

function SQLQueries:ClearDashboard()
    return "DELETE FROM " .. self.dbname .. ".dbo.tableWidgets WHERE (DashboardID = '%s')"
end

function SQLQueries:DeleteDashboard()
    return "DELETE FROM " .. self.dbname .. ".dbo.tableDashboards WHERE (ID = '%s')"
end

function SQLQueries:GetContentChartID()
    return "SELECT convert(nvarchar(50), ID) as ID" ..
    "FROM " .. self.dbname ..".dbo.tableEmbeddedContents" ..
    "WHERE (Name = '%s')"
end

function SQLQueries:CreateEmbeddedContentChart()
    return "EXECUTE " .. self.dbname ..".usp_SaveEmbeddedContent" .. 
    [[@id = '%s', 
    @name = '%s',
    @infoDisplayFormat = 0,
    @show = 1,     
    @contentURL = '%s',
    @groupName =    '%s',
    @calculationType = 0]]
end

function SQLQueries:SetContentUrl()
    return "UPDATE " .. self.dbname .. 
    ".dbo.tableEmbeddedContents SET ContentURL = '%s' WHERE (Name = '%s')"
end

function SQLQueries:EmbeddedContentChartExists()
    return [[SELECT COUNT([Name])
    FROM [dbo].[tableEmbeddedContents]
    WHERE ([Name] = '%s')]]
end

function SQLQueries:ClearAllBookmarks()
    return "DELETE FROM " .. self.dbname .. ".dbo.tableBookmarks"
end

function SQLQueries:AddBookmark()
    return "INSERT INTO " .. self.dbname .. ".dbo.tableBookmarks" .. 
    [[(ID, ProfileID, Name, Description, DisplayOrder, Icon, ObjectID, URI) 
    VALUES ('%s', '%s', '%s', '', 0, 'tf-dashboard22', '%s', '%s')]]
end

function SQLQueries:BookmarkCount()
    return "SELECT COUNT(NAME) FROM " .. self.dbname .. ".dbo.tableBookmarks".. 
    [[WHERE (ProfileID = '%s')
    AND (Name = '%s')
    AND (ObjectID = '%s')]]
end

function SQLQueries:InsertDashboardLinkBlock()
    return "INSERT INTO " .. self.dbname .. ".dbo.tableDashboardLinkBlockWidgetOptions".. 
    [[(ID, WidgetID, Icon, Color, DashboardID)
    VALUES ('%s', 
    '%s', 
    'tf-dashboard22', 
    '#ced5d7', 
    '%s')]]
end


local hackbox = hackbox or {}
function hackbox.deepcopy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[hackbox.deepcopy(k, s)] = hackbox.deepcopy(v, s) end
  return res
end


local AutomatedDashboardGenerator =
{
  catLib = require "inmation.Catalog",
  modLib = require "inmation.ObjectModelBASF",
  logswitch = false,
  modelsFoundInVKPI = {},
  DB = require 'esi-odbc',
  GridPlacers = nil, --is initialized at database connection establishment
  ODBCConnectionData = 
  {
    ["dsn"] = "vkpiadmin1",
    ["user"] = "sa",
    ["password"] = "1877Mtk!1"
  },
  --name of the vkpi database instances availible in database
  AvailibleDatabases =
  {
    ["admin"] = "visualkpi",
    ["visualkpitg"] = "visualkpitg",
    ["Technische Gase"] = "visualkpitg",
    ["visualkpisc"] = "visualkpisc",
    ["Steamcracker"] = "visualkpisc",
    ["visualkpieo"] = "visualkpieo",
    ["Ethylenoxid"] = "visualkpieo",
    ["visualkpika"] = "visualkpika",
    ["Klaeranlage"] = "visualkpika",
	["visualkpipg"] = "visualkpipg",
	["PGS"] = "visualkpipg"
  },
  CurrentlySelectedDatabase = "admin",
  SQLQueries = SQLQueries,

  --a table defining the VKPI database entries based on the user-defined mapping options
  --ensures vailidity of the tableWidgets
  --the MappingTable has to have a field with the name given in options.howto argument in the addWidgetToProfile method
  MappingTable = VKPIMappingTable,

  new = function(self, o)
    --without the deepcopy(self) here, all table field of the object point to the same table
    o = o or hackbox.deepcopy(self) 
    self.__index = self
    setmetatable(o, self)
    
    return o
  end,

  --continue here
  tryConnectDatabase = function(self)
    self.db = ODBC:GETCONNECTION
    {
        self.ODBCConnectionData["dsn"], 
        self.ODBCConnectionData["user"], 
        self.ODBCConnectionData["password"]
    }
    self.GridPlacers = {}

    self:selectDataBase('admin')
    return true
  end,

  selectDataBase = function(self, databasename)
    if self.AvailibleDatabases[databasename] == nil then
      error("unknown VKPI database: " .. databasename, 2)
    else
      self.CurrentlySelectedDatabase = databasename
      self.SQLQueries:set(self.AvailibleDatabases[databasename])
    end

    local sql = 'USE ' .. self.AvailibleDatabases[databasename]
    self.db:rows(sql)
  end,

  disconnectDatabase = function(self)
    self.DB:CLOSE()
    self.GridPlacers = nil
  end,

  dispose = function(self)
    self.DB:DISCONNECT()
  end,

  --attention: this can cause race conditions!
  setDefaultDashboard = function(self, DashboardName)
    if not self:dashboardExists(DashboardName) then
      error("The dashboard with name " .. DashboardName .. " cannot be set to default since it does not exist!", 2)
    end
    local sql = SQLQueries:ResetAllDefaultDashboards()
    self.DB:EXECUTE(sql)
    local sql = SQLQueries.SetDefaultDashboard:format(DashboardName)
    sql = sql:format(DashboardName)
    self.DB:EXECUTE(sql)
  end,

  --test this!
  --attention: this can cause race conditions!
  setDefaultProfile = function(self, ProfileName)
    if not self:profileExists(ProfileName) then
      error("The profile with name " .. ProfileName .. " cannot be set to default since it does not exist!", 2)
    end
    local sql = SQLQueries.ResetAllDefaultProfiles
    self.db:rows(sql)
    local sql = SQLQueries.SetDefaultProfile:format(ProfileName)
    sql = sql:format(ProfileName)
    self.db:rows(sql)
  end,


  --tested
  clearCurrentDatabase = function(self)
    local sql = SQLQueries.ClearDataBase
    self.db:rows(sql)
  end,



  ----------------------------------------PROFILE  STUFF
  ensureProfile = function(self, ProfileName, ProfileDescription)
    if self:profileExists(ProfileName) then
      self:setProfileDescription(ProfileName, ProfileDescription)
      return false --todo: set profile description
    else
      self:createProfile(ProfileName, ProfileDescription)
    end
  end,


  --checks whether the profile name already exists globally (independent of the parent group!)
  --additionally checks whether the profile exists only exactly ONCE!
  --checked
  profileExists = function(self, ProfileName)
    if ProfileName==nil or ProfileName == "" then
      error("ProfileName cannot be nil or empty!", 3)
    end
    local sql = SQLQueries.ProfileExists:format(ProfileName)
    local count
    for row in self.db:rows(sql, 1) do
      count = row[1]
    end

    if count == 1 then
      return true
    elseif count == 0 then
      return false
    else
      error("The Profile with name " .. ProfileName .. " exists " .. count .. " times!")
    end
  end,



  --not used internally
  getProfileNames = function(self)
    local sql = SQLQueries.GetAllProfileNames
    local profilenames ={}
    for row in self.db:rows(sql) do --this query does perhaps not return any results!
      table.insert(profilenames, row[2])
    end
    return profilenames
  end,


  --returns nil if the profile does not exist
  getProfileID = function(self, ProfileName)
    local sql = SQLQueries.GetProfileID:format(ProfileName)
    local id
    for row in self.db:rows(sql) do
      id = row[1]
    end
    return id
  end,


  --checked
  getProfilesByDescription = function(self, ProfileDescription)
    local sql = SQLQueries.GetProfilesByDescription:format(ProfileDescription)
    local profiles = {}
    for row in self.db:rows(sql) do
      table.insert(profiles, {id=row[1], name=row[2]})
    end
    return profiles
  end,


  --checked
  deleteProfile = function(self, ProfileName)
    if not self:profileExists(ProfileName) then
      return false
    end

    local dashboards = self:getDashboardsInProfile(ProfileName)
    for _, db in pairs(dashboards) do
      self:deleteDashboard(db.name)
    end

    local id = self:getProfileID(ProfileName)
    local sql = SQLQueries.DeleteProfile:format(ProfileName)
    self.db:rows(sql)
    return true
  end,


  clearProfile = function(self, ProfileName)
    if not self:profileExists(ProfileName) then
      return false
    end

    local dashboards = self:getDashboardsInProfile(ProfileName)
    for _, db in pairs(dashboards) do
      self:deleteDashboard(db.name)
    end
    return true
  end,



  --creates a profile with a specified name and parent group EVEN IF IT EXISTS!
  --checked
  createProfile = function(self, ProfileName, ProfileDescription)
    if ProfileDescription == nil then
      ProfileDescription = ""
    end
    local sql = SQLQueries.SaveProfile:format(self:newID(), ProfileName, ProfileDescription)
    self.db:rows(sql)
    return true
  end,

  setProfileDescription = function(self, ProfileName, ProfileDescription)
    local sql = SQLQueries.SetProfileDescription:format(ProfileDescription, ProfileName)
    self.db:rows(sql)
  end,


  ----------------DASHHBOARD RELATED STUFF


  --gets a dashboard id for a profile name
  --returns nil if the profile does not exist!
  --checked
  getDashboardID = function(self, DashboardName)
    if DashboardName==nil or DashboardName=="" then
      error("DashboardName is nil or empty!", 3)
    end
    local sql = SQLQueries.GetDashboardID:format(DashboardName)
    local id
    for row in self.db:rows(sql) do
      id = row[1]
    end
    return id
  end,


  --checked
  dashboardExists = function(self, DashboardName)
    if not self:getDashboardID(DashboardName) then
      return false
    else
      return true
    end
  end,


  --former getProfilesInProfileGroup
  --checked
  getDashboardsInProfile = function(self, ProfileName)
    local id = self:getProfileID(ProfileName)
    local sql = SQLQueries.GetDashboardsByDescription:format(id)
    local dashboards = {}
    for row in self.db:rows(sql) do
      table.insert(dashboards, {id=row[1], name=row[2]})
    end
    return dashboards
  end,

  getDashboardsByDescription = function(self, DashboardDescription)
    local sql = SQLQueries.GetDashboardsByDescription:format(DashboardDescription)
    local dashboards = {}
    for row in self.db:rows(sql) do
      table.insert(dashboards, row[2])
    end
    return dashboards
  end,


  --former ensureProfileInParentGroup
  --updates description if necessary
  --checked
  ensureDashboardInParentProfile = function(self, ParentProfileName, DashboardName, DashboardDescription)
    if not self:profileExists(ParentProfileName) then
      error("The parent profile " .. tostring(ParentProfileName) .. " does not exist!", 2)
      return false
    end

    if DashboardDescription == nil then
      DashboardDescription = ""
    end

    if not self:dashboardExists(DashboardName) then --create dashboard
      local id = self:getProfileID(ParentProfileName)
      local sql = SQLQueries.NewDashboard:format(DashboardName, DashboardDescription, id)
      self.db:rows(sql)
      return true
    else --des description
      local id = self:getDashboardID(DashboardName)
      local sql = SQLQueries.UpdateDashboardDescription:format(DashboardDescription, id)
      self.db:rows(sql)
      return true
    end
  end,



  --Trys to deletes all widgets associated with this profile
  --former clearProfile
  --checked
  clearDashboard = function(self, DashboardName)
    if not self:dashboardExists(DashboardName) then
      error("Could not clear the Dashboard " .. DashboardName .. " since does not exist! Create it first with :ensureDashboard!", 2)
      return false
    end

    local dashboardid = self:getDashboardID(DashboardName)
    self.GridPlacers[dashboardid] = GridPlacer:new()
    local sql = SQLQueries.ClearDashboard:format(dashboardid)
    self.db:rows(sql)
    return true
  end,


  --former deleteProfile
  deleteDashboard = function(self, DashboardName)
    if not self:dashboardExists(DashboardName) then
      return false
    end
    self:clearDashboard(DashboardName) --deletes the widgets
    local id = self:getDashboardID(DashboardName)
    if id == nil then
      return false
    end
    local sql = SQLQueries.DeleteDashboard:format(id)
    self.db:rows(sql)
    return true
  end,





  ----------EMBEDDED CONTENT STUFF
  ensureEmbeddedContentChart = function(self, ContentName, URL)
    if self:embeddedContentChartExists(ContentName) then
      --inmation.log(1, "chart exists, content name " .. ContentName)
      self:setContentURL(ContentName, URL)
    else
      --inmation.log(1, "chart doesnt exist, content name " .. ContentName)
      self:createEmbeddedContentChart(ContentName, URL)
    end
    local id = self:getContentChartID(ContentName)
    --inmation.log(1, "chart id " .. id)
    if id == nil then
      error("Unexpected Error!")
    end
    return id
  end,


  getContentChartID = function(self, ContentName)
    local sql = SQLQueries.GetContentChartID:format(ContentName)
    --inmation.log(1, "getting content chart id, sql: " .. sql)
    for row in self.db:rows(sql) do
      id = row[1]
    end
    return id
  end,

  --checked
  createEmbeddedContentChart = function(self, ContentName, URL)
    local embeddedcontentid = self:newID()
    local sql = SQLQueries.CreateEmbeddedContentChart:format(embeddedcontentid, ContentName, URL, '-- Home --')
    --inmation.log(1, "chart is created, sql: " .. sql)
    self.db:rows(sql)
  end,
  --GO ON HERE
  setContentURL = function(self, ContentName, URL)
    local sql = SQLQueries.SetContentUrl:format(URL, ContentName)
    --inmation.log(1, "setting url, sql: " .. sql)
    self.db:rows(sql)
  end,


  --checked
  embeddedContentChartExists = function(self, ContentName)
    local sql = SQLQueries.EmbeddedContentChartExists:format(ContentName)
    local count
    --inmation.log(1, "checking existence, sql: " .. sql)
    for row in self.db:rows(sql) do
      count = row[1]
    end
    if count==1 then
      return true
    elseif count==0 then
      return false
    else
      error("The ContentName " .. ContentName .. " exists more than once!", 2)
    end
  end,


  ----------Bookmark stuff
  --the bookmark names has to be equal to the dashboard name!
  ensureBookmarkForAllProfiles = function(self, BookmarkedDashboardName)
    local profilenames = self:getProfileNames()
    for _, name in pairs(profilenames) do
      self:ensureBookmark(name, BookmarkedDashboardName)
    end
  end,

  ensureBookmark = function(self, TargetProfileName, BookmarkedDashboardName)
    if self:bookmarkExists(TargetProfileName, BookmarkedDashboardName) then
      return false
    else
      self:addBookmark(TargetProfileName, BookmarkedDashboardName)
      return true
    end
  end,

  clearAllBookmarks = function(self)
    local sql = SQLQueries.ClearAllBookmarks
    self.db:rows(sql)
  end,

  addBookmark = function(self, TargetProfileName, BookmarkedDashboardName)
    local targetprofilid = self:getProfileID(TargetProfileName)
    local bookmarkdbid = self:getDashboardID(BookmarkedDashboardName)
    if not targetprofilid then
      error("The profile " .. TargetProfileName .. " does not exist!", 3)
    end
    if not bookmarkdbid then
      error("The dashboard " .. BookmarkedDashboardName .. " does not exist!", 3)
    end

    --'Dashboard|d9925737-5dd7-474e-9b9d-ba307bd5a6a9|db|1'
    local URI = 'Dashboard|' .. tostring(bookmarkdbid) ..'|db|1'
    local sql = SQLQueries.AddBookmark:format(self:newID(), targetprofilid, BookmarkedDashboardName, bookmarkdbid, URI)
    self.db:rows(sql)
  end,


  bookmarkExists = function(self, TargetProfileName, BookmarkedDashboardName)
    local targetprofilid = self:getProfileID(TargetProfileName)
    local bookmarkdbid = self:getDashboardID(BookmarkedDashboardName)
    if not targetprofilid then
      error("The profile " .. TargetProfileName .. " does not exist!", 3)
    end
    if not bookmarkdbid then
      error("The dashboard " .. BookmarkedDashboardName .. " does not exist!", 3)
    end

    local sql = SQLQueries.BookmarkCount:format(targetprofilid, BookmarkedDashboardName, bookmarkdbid)

    local count
    for row in self.db:rows(sql, 1) do
      count = row[1]
    end

    if count == 1 then
      return true
    elseif count == 0 then
      return false
    else
      error("The dashboard bookmark with name " .. BookmarkedDashboardName .. " in profile " .. TargetProfileName .. " exists multiple times!")
    end

  end,





  ----------Dashboard link widget stuff
  ensureDashboardLinkBlock = function(self, linkeddashboardname, widgetid)

    local id = self:newID()
    local targetid = self:getDashboardID(linkeddashboardname)
    --local widgetid = self:newID()
    local defaulttargetid = "D9925737-5DD7-474E-9B9D-BA307BD5A6A9"

    if targetid == nil then
      targetid = defaulttargetid
    end

    local sql = SQLQueries.InsertDashboardLinkBlock:format(id, widgetid, targetid)
    self.db:rows(sql)
    return widgetid
  end,



  ----------------WIDGET RELATED STUFF


  treatSize = function(self, opts, vkpiMappingData, lookup)
    if opts ~= nil and opts.width ~= nil then
      if not self.MappingTable[lookup].PossibleWidhts[tostring(opts.width)] then
        error("invalid width " .. opts.width .. " for lookup type " .. lookup, 3)
      else
        vkpiMappingData.Width = tonumber(opts.width)
      end
    else
      vkpiMappingData.Width = self.MappingTable[lookup].StandardWidth
    end
    if opts ~= nil and opts.height ~= nil then
      if not self.MappingTable[lookup].PossibleHeights[tostring(opts.height)] then
        error("invalid height " .. opts.height .. " for lookup type " .. lookup, 3)
      else
        vkpiMappingData.Height = tonumber(opts.height)
      end
    else
      vkpiMappingData.Height = self.MappingTable[lookup].StandardHeight
    end
  end,

  --former addWidgetToProfile
  --can also be used as function(self, DashboardName, Contentname, ContentURL, {width = 4, height = 8})
  --can also be used as function(self, TargetDashboardName, LinkedDashboardName, {width = 4, height = 8})
  addWidgetToDashboard = function(self, DashboardName, inmationobject, options, opts)
    if DashboardName == nil or DashboardName =="" or type(DashboardName) ~= 'string' then
      error("Invalid argument for DashboardName!", 2)
    end
    if inmationobject == nil then
      error("the given inmation kpi model object is nil!", 2)
    end
    if type(inmationobject)=="table" and inmationobject.ObjectName == nil then
      error("Invalid inmationobject!", 2)
    end
    local dashboardid = self:getDashboardID(DashboardName)
    if dashboardid == nil then
      error("Could not add widget to Dashboard! The Dashboard does not exist!", 2)
    end

    if self.GridPlacers == nil then
      error("You at first have to establish a database connection!", 2)
    elseif self.GridPlacers[dashboardid] == nil then
      error("you have to use :clearDashboard first!", 2)
    end

    local vkpiMappingData
    if type(DashboardName)=='string' and type(inmationobject)=='table' then  --treat inmation objects
      vkpiMappingData = self:mapInmationObjectToVKPIWidget(inmationobject, options)

    elseif type(DashboardName)=='string' and type(inmationobject)=='string' 
      and type(options)=='string' then --treat newly created embedded content object
      local contentname = inmationobject
      local url = options
      local lookup = "EmbeddedContent"
      vkpiMappingData = {}
      --treat width/height
      self:treatSize(opts, vkpiMappingData, lookup)
      vkpiMappingData.ObjectID = self:ensureEmbeddedContentChart(contentname, url)
      inmation.log(1, "ensured embedded content: " .. contentname .. " " .. url)
      vkpiMappingData.ObjectType = self.MappingTable[lookup].ObjectType
      vkpiMappingData.WidgetType = self.MappingTable[lookup].WidgetType
      vkpiMappingData.MetaDescription = self.MappingTable[lookup].MetaDescription
      vkpiMappingData.URI = self.MappingTable[lookup].URIWithoutID .. vkpiMappingData.ObjectID
    elseif type(inmationobject)=='string' and (type(options)=='nil' or type(options)=='table') and type(opts)=='nil' then --treat dashboard links
      --treat dashboard links
      local lookup = "DashboardLink"
      vkpiMappingData = {}
      --treat width/height
      self:treatSize(options, vkpiMappingData, lookup)
      --vkpiMappingData.Width = self.MappingTable[lookup].StandardWidth
      --vkpiMappingData.Height = self.MappingTable[lookup].StandardHeight
      vkpiMappingData.ObjectID = '7EE27D6E-A1CB-48CD-A073-2968AF67F477' --is always the same for DashboardLinks
      vkpiMappingData.ObjectType = self.MappingTable[lookup].ObjectType
      vkpiMappingData.WidgetType = self.MappingTable[lookup].WidgetType
      vkpiMappingData.MetaDescription = self.MappingTable[lookup].MetaDescription
      vkpiMappingData.URI = 'null' 
      vkpiMappingData.LinkDashboard = true
    else
      error("Invalid type for inmationobject! Expected table (inmation object), got " .. type(inmationobject), 2)
    end


    if vkpiMappingData.ObjectID == nil or vkpiMappingData.ObjectID == "" then
      error("The RCS has not assigned a VKPI ID to this object yet!")
    end
    local widgetid = self:newID() --changed
    local rowstart, rowend, columnstart, columnend = self.GridPlacers[dashboardid]:placeObject(vkpiMappingData.Height, vkpiMappingData.Width)
    local sql = [[INSERT INTO tableWidgets(ID, DashboardID, RowStart, RowEnd , 
                    ColumnStart, ColumnEnd, ObjectType, ObjectID, WidgetType, MetaDescription, URI)
                   VALUES ('%s', '%s', %s, %s, %s, %s, %s,'%s', %s, '%s', %s)]]--changed: widget id (ID here) added!
    if tostring(vkpiMappingData.URI)~='null' then
      vkpiMappingData.URI = "'" .. tostring(vkpiMappingData.URI) .. "'"
    end
    sql = string.format(sql, 
      widgetid,
      dashboardid,
      tostring(rowstart),
      tostring(rowend),
      tostring(columnstart),
      tostring(columnend),
      tostring(vkpiMappingData.ObjectType),
      tostring(vkpiMappingData.ObjectID),
      tostring(vkpiMappingData.WidgetType),
      tostring(vkpiMappingData.MetaDescription),
      tostring(vkpiMappingData.URI))

    local ok, err = pcall(function()
        self.db:rows(sql)
      end)
    if not ok then
      error("Error mapping object at path " .. inmationobject:path() .. ", exception: " .. err)
    end

    --this has to happen apper inserting the table widget!
    if vkpiMappingData.LinkDashboard then
      self:ensureDashboardLinkBlock(inmationobject, widgetid);
    end

    return true
  end,



  --inmationobject is a (table) object gathered by inmation.get(path)
  --options is a optional table with the fields: howto, width, height. if invalid values are supplied an error is thrown
  mapInmationObjectToVKPIWidget = function(self, inmationobject, options)
    if inmationobject == nil then
      error("inmationobject is nil!", 3)
    end
    if type(inmationobject) ~= "table" then
      error("inmationobject does not have a valid object type! Type " .. type(inmationobject), 3)
    end

    --logic for treating the homegroup
    local lookup, vkpiObjectID = self:identifyInmationObject(inmationobject, options)
    local vkpiObjectIDinURI = vkpiObjectID 
    if options and options.homegroup then
      vkpiObjectIDinURI = '7EE27D6E-A1CB-48CD-A073-2968AF67F477'
      vkpiObjectID = '7EE27D6E-A1CB-48CD-A073-2968AF67F477'
    end

    --STEP 2: create the database entries based on a mapping table
    local vkpiMappingData = {}
    --treat width/height
    if options ~= nil and options.width ~= nil then
      if not self.MappingTable[lookup].PossibleWidhts[tostring(options.width)] then
        error("invalid width " .. options.width .. " for lookup type " .. lookup, 3)
      else
        vkpiMappingData.Width = tonumber(options.width)
      end
    else
      vkpiMappingData.Width = self.MappingTable[lookup].StandardWidth
    end
    if options ~= nil and options.height ~= nil then
      if not self.MappingTable[lookup].PossibleHeights[tostring(options.height)] then
        error("invalid height " .. options.height .. " for lookup type " .. lookup, 3)
      else
        vkpiMappingData.Height = tonumber(options.height)
      end
    else
      vkpiMappingData.Height = self.MappingTable[lookup].StandardHeight
    end

    vkpiMappingData.ObjectType = self.MappingTable[lookup].ObjectType
    vkpiMappingData.ObjectID = vkpiObjectID
    vkpiMappingData.WidgetType = self.MappingTable[lookup].WidgetType
    vkpiMappingData.MetaDescription = self.MappingTable[lookup].MetaDescription
    vkpiMappingData.URI = self.MappingTable[lookup].URIWithoutID .. vkpiObjectIDinURI

    return vkpiMappingData
  end,


  --gets am inmation object and returns a lookup (entry in the self.MappingTable) and the inmation object ID
  identifyInmationObject = function(self, inmationobject, options)
    --STEP1: identify the given VKPI Object and how to map it to VKPI
    local type_meaning, type_code = inmationobject:type()

    local propertypath, lookup

    --------------------treatmeant of chart-like inmation kpimodel objects
    if type_code == inmation.model.classes.Chart then
      if inmationobject.ChartType == inmation.model.codes.SelectorChartType.CHART_PARETO then
        propertypath = ".ParetoChart.KPIParetoChartID"
        lookup = "ParetoChart"
      elseif inmationobject.ChartType == inmation.model.codes.SelectorChartType.CHART_TREND then
        propertypath = ".TrendChart.KPITrendID"
        lookup = "TrendChart"
      elseif inmationobject.ChartType == inmation.model.codes.SelectorChartType.CHART_BAR then --has 
        propertypath = ".BarChart.KPIBarChartID"

      elseif inmationobject.ChartType == inmation.model.codes.SelectorChartType.CHART_XYPLOT then
        propertypath = ".XYPlotChart.KPIXYPlotID"
        lookup = "XYPlot"
      elseif inmationobject.ChartType == inmation.model.codes.SelectorChartType.CHART_PIE then
        propertypath = ".PieChart.KPIPieChartID"

      end
      --------------------treatmeant of kpi-like inmation kpimodel objects
    elseif type_code == inmation.model.classes.GenKPI then 
      propertypath = ".ID"
      lookup = "KPITrend" --standard option
      if options~=nil and options.howto~=nil then
        --mapping as trend
        if options.howto == "KPITrend" then
          lookup = "KPITrend"
          --mapping as KPI Block
        elseif options.howto == "KPIBlock" then
          lookup = "KPIBlock"
        else
          error("unknown mapping option for a " .. type_meaning .. " Object: " .. tostring(options.howto), 4)
        end
      end
      --------------------treatmeant of group-like inmation kpimodel objects
    elseif type_code == inmation.model.classes.KPIGroup
    or type_code == inmation.model.classes.Area
    or type_code == inmation.model.classes.Plant
    or type_code == inmation.model.classes.PlantCompound
    or type_code == inmation.model.classes.Division
    or type_code == inmation.model.classes.Site
    or type_code == inmation.model.classes.Enterprise
    then
      propertypath = ".ID"
      lookup = "GroupList" --this is the standard option. can also be mapped as KPIMap and KPIBullet
      if options~=nil and options.howto~=nil  then
        if self.MappingTable[options.howto] ~= nil then
          lookup = options.howto
        elseif options.howto == "GroupList" then
          lookup = "GroupList"
        elseif options.howto == "GroupListExpanded" then
          lookup = "GroupListExpanded"
        elseif options.howto == "KPIMap" then --KPI Maps can be grouped by group or status
          lookup = "KPIMap"
        elseif options.howto == "KPIMapGroup" then
          lookup = "KPIMapGroup"
        elseif options.howto == "KPIMapStatus" then
          lookup = "KPIMapStatus"
        elseif options.howto == "KPIMapStatusFilterGood" then
          lookup = "KPIMapStatusFilterGood"
        elseif options.howto == "KPIMapGroupFilterGood" then
          lookup = "KPIMapGroupFilterGood"
        elseif options.howto == "KPIMapGroupFilterGoodAndLows" then
          lookup = "KPIMapGroupFilterGoodAndLows"
        elseif options.howto == "KPIMapGroupOnlyGood" then
          lookup = "KPIMapGroupOnlyGood"
        elseif options.howto == "KPIBullet" then
          lookup = "KPIBullet"
        elseif options.howto == "KPIBulletGroup" then
          lookup = "KPIBulletGroup"
        elseif options.howto == "KPIBulletStatus" then
          lookup = "KPIBulletStatus"
        elseif options.howto == "KPISummaryHistory" then
          lookup = "KPISummaryHistory"
        elseif options.howto == "KPIStatusHistory" then
          lookup = "KPIStatusHistory"
        elseif options.howto == "ChartList" then
          lookup = "ChartList"
        elseif options.howto == "ChartListGroup" then
          lookup = "ChartListGroup"
        elseif options.howto == "ChartListChartType" then
          lookup = "ChartListChartType"
        elseif options.howto == "GroupBlock" then
          lookup = "GroupBlock"
        else
          error("unknown mapping option for a " .. type_meaning .. " Object: " .. tostring(options.howto), 4)
        end
      end

      --------------------treatmeant of all other inmation objects 
    else
      error("incompatible object type: " .. type_meaning .. ", only chart and kpi objects are supported at the moment!", 4)
    end
    local vkpiObjectID = inmation.getvalue(inmationobject:path() .. propertypath)
    if lookup == nil then
      error("unsupported vkpi object!", 4)
    end
    return lookup, vkpiObjectID
  end,


  setDashboardLink = function(self, alarmkpiobj, targetdashboardname)
    if targetdashboardname==nil then
      error("targetdashboardname is nil!", 2)
    end
    local uri
    if alarmkpiobj:type() ~= "MODEL_CLASS_GENKPI" then
      error("Only KPI Objects can be linked with a dashboard", 2)
    end

    if not self:dashboardExists(targetdashboardname) then
      error("A dashboard with name " .. targetdashboardname .. " does not exist in the currently selected instance!", 2)
    end
    uri = "dashboard:"

    local dashboardid = self:getDashboardID(targetdashboardname)
    uri = uri .. dashboardid:lower()
    inmation.setvalue(alarmkpiobj:path() .. '.Links', uri)
    inmation.setvalue(alarmkpiobj:path() .. '.KPINameClickPath', inmation.model.codes.KPINameClickPath.URL)
  end,



  newID = function(self)
    if _GLOBALADD == nil then
      _GLOBALADD = 0
    end
    math.randomseed(inmation.now()+_GLOBALADD+inmation.getself():numid())
    _GLOBALADD = _GLOBALADD + 1
    local template ='xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'

    local newid = string.gsub(template, '[xy]', 
      function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
      end)
    return newid
  end,


  testRoutine2 = function(self)

    self:connectToDatabase()

    self:selectDataBase("Test")

    self:ensureProfile("TestProfile")
    self:ensureDashboardInParentProfile("TestProfile", "TestDashboard")
    self:clearDashboard("TestDashboard")

    local groupobj = inmation.getobject("/BASF/Predictive Maintenance/EMEA/Ludwigshafen/Steamcracker (Prediction)/A100/W100A")
    local kpiobj = inmation.getobject("/BASF/Predictive Maintenance/EMEA/Ludwigshafen/Steamcracker (Prediction)/A100/W100A/T_out Trend W100A")
    local trendobj = inmation.getobject("/BASF/Predictive Maintenance/EMEA/Ludwigshafen/Steamcracker (Prediction)/A100/W100A/days_online")


    --add an embedded content
    --(DashboardName, Contentname, ContentURL, {width = 4, height = 8})
    --works after next caching
    self:addWidgetToDashboard("TestDashboard", "TestContentName", "http://myfirstazurewebapp20171115023835.azurewebsites.net/")

    --add a dashboard link
    --(TargetDashboardName, LinkedDashboardName, {width = 4, height = 8})
    self:addWidgetToDashboard("TestDashboard", "Default");

    --add a dashboard link widget to the dashbord "default" pointing to the dashboard "TestDashboard"
    self:clearDashboard("Default")
    self:addWidgetToDashboard("Default", "TestDashboard"); --does not work since default dashboard was n

    self:addWidgetToDashboard("TestDashboard", groupobj, {howto = "GroupBlock", width = 1})

    --adds a bookmark to the profile with name "TestProfile" to the Dashboard with name "Default"
    self:ensureBookmark("TestProfile", "Default")
    --adds a bookmark to the profile with name "Default" to the Dashboard with name "TestDashboard"
    self:ensureBookmark("Default", "TestDashboard")
    --adds a bookmark to the dashboard "TestDashboard" for all profiles
    self:ensureBookmarkForAllProfiles("TestDashboard")


    --test mapping of group objects
    self:addWidgetToDashboard("TestDashboard", groupobj, {howto = "GroupBlock", width = 2})
    self:addWidgetToDashboard("TestDashboard", groupobj, {howto = "KPIMap", width = 4})
    self:addWidgetToDashboard("TestDashboard", groupobj, {howto = "KPIMapGroup", width = 4})
    self:addWidgetToDashboard("TestDashboard", groupobj, {howto = "KPIMapStatus", width = 4})

    self:addWidgetToDashboard("TestDashboard", groupobj, {howto = "ChartList", width = 4})
    self:addWidgetToDashboard("TestDashboard", groupobj, {howto = "ChartListChartType", width = 4})
    self:addWidgetToDashboard("TestDashboard", groupobj, {howto = "ChartListGroup", width = 4})

    self:addWidgetToDashboard("TestDashboard", groupobj, {howto = "KPIBullet", width = 4})
    self:addWidgetToDashboard("TestDashboard", groupobj, {howto = "KPIBulletGroup", width = 4})
    self:addWidgetToDashboard("TestDashboard", groupobj, {howto = "KPIBulletStatus", width = 4})

    self:addWidgetToDashboard("TestDashboard", groupobj, {howto = "KPISummaryHistory", width=2})
    self:addWidgetToDashboard("TestDashboard", groupobj, {howto = "KPIStatusHistory", width=2})

    --test mapping of kpi objects
    self:addWidgetToDashboard("TestDashboard", kpiobj, {howto = "KPIBlock"})
    self:addWidgetToDashboard("TestDashboard", kpiobj, {howto = "KPITrend", width=2})

    --test mapping of trend objects
    self:addWidgetToDashboard("TestDashboard", trendobj, {width=4})

    --test invalid width
    local ok, err = pcall(function() self:addWidgetToDashboard("TestProfile", kpiobj, {howto = "KPIBlock", width = 3}) end)
    if ok then error("An error should have been raised!") end


    --test the homegroup
    self.ADG:addWidgetToDashboard("TestDashboard", inmation.getobject("/BASF"), {howto="GroupList", homegroup=true})


    --test deleting etc
    self:ensureProfile("TestProfile2")
    self:ensureDashboardInParentProfile("TestProfile2", "TestDashboard2")
    local a = self:getDashboardsInProfile("TestProfile2")
    if #a==0 then
      error("")
    end
    if a[1].name~="TestDashboard2" then
      error("dbs in testprofile 2: " .. table.concat(a, " "))
    end
    self:deleteProfile("TestProfile2")
    if self:dashboardExists("TestDashboard2") then
      error("The dashboard should have been deleted!")
    end




    self:disconnectDatabase()

    do return "passed" end

  end,
}



local DashboardGeneratorFactory
=
{
  getNewDashboardGenerator = function(self)
    local a = AutomatedDashboardGenerator:new()
    local success = a:tryConnectDatabase()
    if not success then
      return nil, "could not acquire lock!"
    end
    return a
  end
}

return DashboardGeneratorFactory
