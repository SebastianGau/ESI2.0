--esi-odbc

local db =
{
--[[@md 
### INFO
This is a mandatory function for every ESI library.

Useage
```lua
    local JSON = require('dkjson')
    local ESI = require('esi-example')
    local result = ESI:INFO()
    error(JSON.encode(result))
```
@md]]
  INFO = function()
    return {
      version = {
        major = 0,
        minor = 1,
        revision = 1
      },
      contacts = {
        {
          name = "Florian Seidl",
          email = "florian.seidl@cts-gmbh.de"
        },
        {
          name = "Sebastian Gau",
          email = "sebastian.gau@basf.com"
        }
      },
      library = {
        -- Filename is always "lib-" .. modulename and the modulename must be used for the ScriptLibrary.LuaModuleName property.
        modulename = "esi-odbc"
      }
    }
  end,


  driver = require "luasql.odbc",
  json = require 'json',
  connection = nil,
  environment = nil,
  name = "", --dsn
  user = "",
  password = "",

  --[[@md 
### CONNECT
Connects to an ODBC source. The odbc source has to be configured on the machine on 
which the command is executed.

Useage
```lua
    local ODBC = require 'esi-odbc'
    ODBC:CONNECT{dsn="dsname", user="user", password="pw"}
```
@md]]
  CONNECT = function(self, args)
    if args.dsn~=nil then
      self.name = args.dsn
    end
    if args.user~=nil then
      self.user = args.user
    end
    if args.password~=nil then
      self.password = args.password
    end
    local env = self.driver:odbc()
    self.environment = env
    local connection = env:connect(self.name, self.user, self.password)
    if connection == nil then
      error("Database connection could not be established! Check login configuration and ODBC settings!")
    else
      self.connection = connection
    end
  end,

--[[@md 
### EXECUTE
Executes an SQL Query/Statement. Returns an iterator if rows have to be iterated.
Throws an exception if the statement cannot be processed.

Useage
```lua
    local sql =  "SELECT      dbo.tableDashboards.ID, dbo.tableDashboards.Name"..
  "FROM        dbo.tableDashboards"..
  "WHERE       (dbo.tableDashboards.Description  LIKE 'asd')"
    local dashboards = {}
    for row in ODBC:EXECUTE(sql) do
      table.insert(dashboards, {id=row[1], name=row[2]})
    end

    --OR:
    local sql = "EXECUTE usp_DeleteProfile 'asd'"
    ODBC:EXECUTE(sql)
```
@md]]
  EXECUTE = function(self, sql, expected)
    if self.connection == nil then
      error("invalid database connection!")
    end
    if sql == nil then
      error('got a nil sql statement!', 2)
    end

    --if we basically only want a execute
    if expected ~= nil and expected == 0 then
      self:execute(sql)
    end

    local cursor, errormsg = self.connection:execute(sql)
    if cursor == nil then
      if errormsg ~= nil and errormsg ~= "" then
        error("error in :rows command: " .. errormsg .. " while executing SQL query : " .. sql, 2)
      elseif errormsg ~= nil and errormsg == "" then
        return "" 
        --for execute querys which do not affect any rows (e.g. a DELETE FROM... which does not delete anything)
      else
        error("unexpected error")
      end
    end
    if type(cursor) == "userdata" then
      --do nothing (return the iterator later)
      --error("The query did not return a cursor! Use :execute instead!", 2)
    elseif type(cursor) == "number" then
      return cursor
    else
      error("unexpected return data type: " .. type(cursor).. ", query: " .. sql)
    end

    local i = 0
    return function()
      local row = cursor:fetch({}, 'n')
      if row then
        i = i + 1
        return row
      else
        cursor:close()
        if i==0 and expected~=nil and type(expected)=="string" then
          error("database query '" .. sql .. "'' did not return a result! Empty results are not allowed!", 2)
        end
        if expected~=nil and type(expected)=="number" and i~=expected then
          error("the query ''" .. sql .. "'' should return " .. expected .. " results but returned " .. i .. " results! ", 2)
        end
        return nil
      end
    end
  end,
  
  --[[@md 
### CLOSE
Closes the ODBC connection. Leads to problems if forgotten.
After closing, no queries can be processed anymore.

Useage
```lua
    ODBC:CLOSE()
```
@md]]
  CLOSE = function(self)
    if self.connection~=nil then
      self.connection:close()
    end
    if self.environment~= nil then
      self.environment:close()
    end
  end
}
return db