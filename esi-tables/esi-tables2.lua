-- esi-tables
local esitbllib =
{
    O = require 'esi-objects',


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
        },
        {
            name = "Timo Klingenmeier",
            email = "timo.klingenmeier@inmation.com"
          },
      },
      library = {
        -- Filename is always "lib-" .. modulename and the modulename must be used for the ScriptLibrary.LuaModuleName property.
        modulename = "esi-tables"
      }
    }
  end,

  config =
  {
    empty = nil
  },

  state =
  {
      mode = "persistoncommand", --or "persistimmediately"
      holderobj = {},
      data = {},
      columns = {}, --columns[columnname] = true
      insync = false,
      columnswritten = false,
      emptyinimage = false,
      wasnewcreated = false
  },

  isempty = function(self)
    return #(self.state.data)==0
  end,

  synctoimage = function(self)
    self.state.holderobj.TableData = self.state.data
    self.state.holderobj:commit()
    self.state.insync = true
  end,

  --problem: sync columns from image with empty table
  syncfromimage = function(self)
    self.state.data = self.state.holderobj.TableData --returns an empty table even if there were columns initialized
    self.state.columns = {}

    if not self.state.data or #(self.state.data)==0 then
      self.state.emptyinimage = true
      self.state.data = {}
    else
      self.state.emptyinimage = false
      for i=1, #(self.state.data) do
        for col, val in pairs(self.state.data[i]) do
          self.state.columns[col] = true
        end
      end
    end
    self.state.insync = true
  end,

  lazysyncfromimage = function(self)
    if not self.state.insync then
      self:syncfromimage()
    end
  end,

  lazysynctoimage = function(self)
    if not self.state.insync then
      self:synctoimage()
    end
  end,

  columnexists = function(self, colname)
    if self.state.columns[colname] then
      return true
    end
    return false
  end,

  syncifnecessary = function(self)
    if self.state.mode == "persistimmediately" then
      self:synctoimage()
    end
  end,


 NEW = function(self, args)
    if not args or type(args)~='table' then error("invalid arguments given: " .. tostring(args)) end
    if not args.path then error("missing path field in arguments table!") end
    local path, oname
    if not args.objectname then
        path, oname = inmation.splitpath(args.path)
    else
        path, oname = args.path, args.objectname
    end

    local o, changed, newcreated = self.O:UPSERTOBJECT{path = path, 
    class="MODEL_CLASS_TABLEHOLDER", 
    properties =
    {
      [".ObjectName"] = oname
    }}

    if not o then
      error("object reference is nil!")
    end

    self.state.holderobj = o
    if args.mode and args.mode~="persistoncommand" then
        self.state.mode = "persistimmediately"
    end
    if newcreated then
      self.state.wasnewcreated = true
    end

    self:syncfromimage()
    return self
 end,



 SAVE = function(self)  
    self:synctoimage()
 end, 


 addcolumn = function(self, colname)
  if not self.state.columns[colname] then
    self.state.columns[colname] = true
    if self.config.empty == nil then return nil end
    for i=1, #(self.state.data) do 
      --this does not do anything if data is empty
      --the columns are then added as soon as rows are added
      self.state.data[i][colname] = self.config.empty
      self.state.insync = false
    end
  else
    error("Cannot add column " .. colname .. " since it already exists!")
  end
end,

removecolumn = function(self, colname)
  if self.state.columns[colname] then
    self.state.columns[colname] = nil
    self.state.insync = false
    for i=1, #(self.state.data) do 
      --this does not do anything if data is empty
      --the columns are then added as soon as rows are added
      self.state.data[i][colname] = nil
      self.state.insync = false
    end
  else
    error("Cannot remove column " .. colname .. " since it does not exist!")
  end
end,

 --t:ADDCOLUMNS{"col1","col2", "col3"}
 --results in table and internal data out of sync!
 ADDCOLUMNS = function(self, args)
    if not args or type(args)~='table' then error("invalid arguments given: " .. tostring(args)) end
    
    for _, colname in pairs(args) do
      if type(colname) == 'string' then
        self:addcolumn(colname)
      else
        error("only string column names allowed!", 2)
      end
    end

    self:syncifnecessary()
    --if empty, example:
    --data["Tags"] = {}
    --inmation.setvalue(o:path() .. '.TableData', self.json.encode({data = data}))
end,



 REMOVECOLUMNS = function(self, args)
    if not args or type(args)~='table' then error("invalid arguments given: " .. tostring(args)) end  
    
    for _, colname in pairs(args) do
      if type(colname) == 'string' then
        self:removecolumn(colname)
      else
        error("only string column names are allowed!", 2)
      end
    end
    self:syncifnecessary()
 end, 


 --ADDROW{col1 = "asd", col2 = 3}
 ADDROW = function(self, args)
    if not args or type(args)~='table' then error("invalid arguments given: " .. tostring(args), 2) end

    local row = {}
    for coltoadd, colvalue in pairs(args) do
      if not self:columnexists(coltoadd) then
        error("Column does not exist : " .. coltoadd, 2)
      end
    end
    for coltoadd, colvalue in pairs(args) do
      row[coltoadd] = colvalue
      self.state.insync = false
    end
    --this is only necessary if self.config.empty is not nil so that "empty" table cells have a default value
    for existingcolumn, _ in pairs(self.state.columns) do
      if not row[existingcolumn] then
        row[existingcolumn] = self.config.empty
      end
    end
    table.insert(self.state.data, row)
    self.state.insync = false

    self:syncifnecessary()
 end,


 match = function(self, where, row)
  if not where then return true end
  if type(row)~='table' then error("Invalid type for row: " .. type(row)) end
  for col, val in pairs(where) do
    if not row[col] then --problem
      return false
    else
      if tostring(row[col]) ~= tostring(where[col]) then
        return false
      end
    end
  end
  return true
end,

valuetype = function(self, var)
  if type(var)=='string' or
  type(var)=='number' or
  type(var)=='boolean' then
    return true
  end
  return false
end,

update = function(self, set, row)
  if not set then return true end
  if type(row)~='table' then error("Invalid type for row: " .. type(row)) end
  for col, val in pairs(set) do
    if self:columnexists(col) then
      if self:valuetype(row[col]) then
        row[col] = set[col]
        self.state.insync = false
      else
        error("invalid type: " .. type(set[col]))
      end
    else
      error("Cannot set nonexistent column, use :ADDCOLUMN before! columnname : " .. tostring(col))
    end
  end
  return true
end,

--  t:UPDATE
-- { 
--     WHERE = {col1 = "asd", col2 = "3"}, --a nonexistent column here will result in an error
--     SET = {col2 = 4, col3 = "asdasd"}
-- }
 UPDATE = function(self, args)
    if not args or type(args)~='table' then error("invalid arguments given: " .. tostring(args), 2) end
    if not args.SET or type(args.SET)~='table' then
      error("Invalid SET argument!")
    end

    local where
    if args.WHERE and type(args.WHERE)~="table" then
      error("Where clause has invalid type!", 2)
    else
      where = args.WHERE
    end

    local updated = 0
    for linenum, row in pairs(self.state.data) do
      if self:match(where, row) then
        if self:update(args.SET, row) then updated = updated + 1 end
      end
    end

    self:syncifnecessary()
    return updated
 end,

 SELECT = function(self, args)
  if not args or type(args)~='table' then error("invalid arguments given: " .. tostring(args), 2) end
  if not args.WHERE or type(args.WHERE)~='table' then
    error("Invalid WHERE argument!")
  end

  local ret = {}
  for linenum, row in pairs(self.state.data) do
    if self:match(where, row) then
      table.insert(ret, row)
    end
  end
  return ret --attention: perhaps return a deep clone here
end,

COLUMNS = function(self)
  local ret = {}
  for col, _ in pairs(self.state.columns) do
    table.insert(ret, col)
  end
  return ret
end,

COLUMNEXISTS = function(self, colname)
  if not colname or type(colname)~='string' then
    error("Invalid argument for columnname! " .. tostring(colname))
  end
  return self:columnexists(colname)
end,

 CLEAR = function(self)
  self.state.data = {}
  self.state.columns = {}
  self.state.wasnewcreated = true
  self.state.insync = false
  self:syncifnecessary()
 end
}
return esitbllib


