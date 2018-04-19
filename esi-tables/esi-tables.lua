-- esi-tables
local esitbllib =
{
    O = require 'esi-objects',
    H = require 'esi-bucket',
    JSON = require 'dkjson',
    SCHEMA = require 'esi-schema',


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
        modulename = "esi-tables",
        dependencies = {
          {
            modulename = 'dkjson',
            version = {
              major = 2,
              minor = 5,
              revision = 0
            }
          },
          {
            modulename = 'esi-objects',
            version = {
              major = 0,
              minor = 1,
              revision = 1
            }
          },
          {
            modulename = 'esi-bucket',
            version = {
              major = 0,
              minor = 1,
              revision = 1
            }
          },
          {
            modulename = 'esi-schema',
            version = {
              major = 0,
              minor = 1,
              revision = 1
            }
          }
        }
      },
    }
  end,

  config =
  {
    emptyidentifier = nil
  },

  state =
  {
      mode = "persistoncommand", --or "persistimmediately"
      holderobj = {},
      data = {},
      columns = {}, --columns[columnname] = true
      insync = false, --means that the holders table and the table inside this object are potentially out of sync
      schema = nil,
      columnssynchronized = false, --means that a non-empty table was read and the columns were extracted
      emptyinimage = false, --means that the table was empty on last reading from the holder
      wasnewcreated = false, --means that the table was new created at the time of initialization
  },

  _isempty = function(self)
    return #(self.state.data)==0
  end,

  _synctoimage = function(self)
    self.state.holderobj.TableData = self.state.data
    self.state.holderobj:commit()
    self.state.insync = true
  end,

  --problem: sync columns from image with empty table
  _syncfromimage = function(self)
    self.state.data = self.state.holderobj.TableData 
    --returns an empty table even if there were columns initialized
    self.state.columns = {}

    if not self.state.data then
      error("Unexpected error: .TableData property returned an empty lua table!")
    end
    if #(self.state.data)==0 then
      self.state.emptyinimage = true
      --self.state.data = {}
      self.state.columnssynchronized = false
    else
      self.state.emptyinimage = false
      for i=1, #(self.state.data) do
        for col, val in pairs(self.state.data[i]) do
          self.state.columns[col] = true
        end
      end
      self.state.columnssynchronized = true
    end
    self.state.insync = true
  end,

  _lazysyncfromimage = function(self)
    if not self.state.insync then
      self:_syncfromimage()
    end
  end,

  _lazysynctoimage = function(self)
    if not self.state.insync then
      self:_synctoimage()
    end
  end,

  _columnexists = function(self, colname)
    if self.state.columns[colname] then
      return true
    end
    return false
  end,

  _syncifnecessary = function(self)
    if self.state.mode == "persistimmediately" then
      self:_synctoimage()
    end
  end,


  


  -- local schema =
  -- {
  --     columns = 
  --     {
  --         {
  --             name = "columnname1",
  --             required = true or false,
  --             unique = true or false,
  --             nonempty = true or false,
  --             valueset = {"asd","sad", 1},
  --             valueset = {discrete = {step = 0.5}} --?
  --             valueset = {luatype="string"},
  --             valueset = {range = {lower = 0, upper = 1}}
  --         },
  --         {
  --             name = "columnname2",
  --             required = true or false,
  --             unique = true or false,
  --             nonempty = true or false,
  --             valueset = {"asd","sad", 1},
  --             valueset = {discrete = {step = 0.5}} --ignored at first
  --             valueset = {luatype="string"},
  --             valueset = {range = {lower = 0, upper = 1}} --ignored at first
  --         },
  --     },
  --     maxrows = 1000,
  -- }

  _validateinputschema = function(self, sc)
    local s = self.SCHEMA

    --maps from integer to string or number
    local valset1 = s.Map(s.Integer, s.OneOf(s.String, s.Number))

    --a table with field "luatype" with values "string" "boolean" or "number"
    local valset2 = s.Record{
      luatype = s.OneOf("string","boolean","number")
    }
    local valset = s.OneOf(valset1, valset2)

    local colelement = s.Record {
      name = s.String,
      required = s.Boolean,
      unique = s.Boolean,
      nonempty = s.Boolean,
      valueset = valset
    }

    local completeSchema = s.Record {
      maxrows = s.PositiveNumber,
      columns = s.Map(s.Integer, colelement) --
    }

    local given = sc --self.state.schema

    local err = s.CheckSchema(given, completeSchema)

    if err then
      return nil, s.FormatOutput(err)
    end
    return true
  end,


  _setschema = function(self, schema)
    self.state.schema = schema
  end,


  _schemacheck = function(self)
    if not self.state.schema then return nil end

  end,


  SETSCHEMA = function(self, schema)
    local ok, err = self:_validateinputschema(schema)
    if not ok then
      error("Error validating input schema: " .. err, 2)
    end
    self:_setschema(schema)
  end,

  --
  VALIDATESCHEMA = function(self)
    local data = self.state.data
    local fails = {}
    local schema = self.state.schema
    if not schema then error("No schema was set!", 2) end

    if schema.maxrows and self:ROWCOUNT() > schema.maxrows then 
      table.insert(fails, "Maximum number of rows exceeded! Count " .. self:ROWCOUNT() .. ", maximum " .. schema.maxrows)
    end

    for _, col in pairs(schema.columns) do
      --check required columns
      if self:COLUMNEXISTS(col.name)==false and col.required then
        table.insert(fails, "mandatory column " .. col.name .. " is missing")
      end
      --start to check the column
      local seen = {}
      for i=1, #(data) do
        local val = data[i][col.name]
        --check emptyness
        if val==self.config.emptyidentifier and col.nonempty then
          table.insert(fails, "empty value for " .. col.name .. " at index " .. i)
        end
        --check uniqueness
        if seen[val] and col.unique then
          table.insert(fails, "double value for column " .. col.name .. " at index " .. i)
        else
          seen[val] = true
        end
        --check type
        if col.valueset then 
          if col.valueset.luatype then --valueset = {luatype="string"},
            if type(val) ~= col.valueset.luatype then
              table.insert(fails, "invalid type for column " .. col.name .. " at index " .. i
              ..", expected " .. tostring(col.valueset.luatype) .. ", got " .. type(val))
            end
          else --valueset {"asd","sad", 1},
            local rev = {}
            for k, v in pairs(col.valueset) do rev[v] = k end
            if not rev[val] then --whats with nil values?
              table.insert(fails, "invalid value for column " .. col.name .. " at index " .. i
              ..", expected values" .. self.JSON.encode(col.valueset) .. ", got " .. tostring(val))
            end
          end
        end
      end
    end
    if #fails>0 then
      return true
    else
      return nil, table.concat(fails, "\n")
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
      error("object reference is nil! Object creation failed!")
    end

    self.state.holderobj = o
    if args.mode and args.mode~="persistoncommand" then
        self.state.mode = "persistimmediately"
    end
    if newcreated then
      self.state.wasnewcreated = true
    end

    self:_syncfromimage()
    return self
 end,



 SAVE = function(self)  
    self:_synctoimage()
 end, 


 _addcolumn = function(self, colname)
  if not self.state.columns[colname] then
    self.state.columns[colname] = true
    if self.config.emptyidentifier == nil then return nil end
    for i=1, #(self.state.data) do 
      --this does not do anything if data is empty
      --the columns are then added as soon as rows are added
      self.state.data[i][colname] = self.config.emptyidentifier
      self.state.insync = false
    end
  else
    error("Cannot add column " .. colname .. " since it already exists!")
  end
end,

_removecolumn = function(self, colname)
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
        self:_addcolumn(colname)
      else
        error("only string column names allowed!", 2)
      end
    end

    self:_syncifnecessary()
    
    --if empty, example:
    --data["Tags"] = {}
    --inmation.setvalue(o:path() .. '.TableData', self.json.encode({data = data}))
end,



 REMOVECOLUMNS = function(self, args)
    if not args or type(args)~='table' then error("invalid arguments given: " .. tostring(args)) end  
    
    for _, colname in pairs(args) do
      if type(colname) == 'string' then
        self:_removecolumn(colname)
      else
        error("only string column names are allowed!", 2)
      end
    end
    self:_syncifnecessary()
 end, 


 --ADDROW{col1 = "asd", col2 = 3}
 ADDROW = function(self, args)
    if not args or type(args)~='table' then error("invalid argument type: " .. tostring(args), 2) end

    local row = {}
    for coltoadd, colvalue in pairs(args) do
      if not self:_columnexists(coltoadd) then
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
        row[existingcolumn] = self.config.emptyidentifier
      end
    end
    table.insert(self.state.data, row)
    self.state.insync = false

    self:_syncifnecessary()
 end,


 _match = function(self, where, row)
  if not where then return true end
  if type(row)~='table' then error("Invalid type for row: " .. type(row)) end
  if type(where)=='table' then
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
  elseif type(where) =='function' then
    local rowrep = self.H.DEEPCOPY(row)
    local match 
    local ok, err = pcall(function() match = where(rowrep) end)
    if not ok then
      local col = self.JSON.encode(rowrep)
      error("Match function caused an error at column " .. col .. ": " .. err, 3)
    end
    if match then
      return true
    end
  elseif type(where) == 'nil' then
    return true
  else
    error("Invalid type for WHERE-field!", 3)
  end
  return false
end,

_valuetype = function(self, var)
  if type(var)=='string' or
  type(var)=='number' or
  type(var)=='boolean' then
    return true
  end
  return false
end,

_update = function(self, set, row)
  if type(row)~='table' then error("Invalid type for row: " .. type(row)) end
  if not set then error("no SET given!") end
  if type(set)=='table' then
    for col, val in pairs(set) do
      if self:_columnexists(col) then
        if self:_valuetype(row[col]) then
          row[col] = set[col]
         -- error("data: "  .. self.json.encode(self.state.data)
        --.. " row[col]: " .. row[col] .. " set[col]: " .. set[col])
          self.state.insync = false
        else
          error("invalid type: " .. type(set[col]))
        end
      else
        error("Cannot set nonexistent column, use :ADDCOLUMN before! columnname : " .. tostring(col))
      end
    end
    return true
  elseif type(set)=='function' then
    local rowrep = self.H.DEEPCOPY(row)
    local ok, err = pcall(function()  set(rowrep) end) --error(self.json.encode(rowrep))
    if not ok then
      local col = self.json.encode(rowrep)
      error("Update function caused an error at column " .. col .. ": " .. err, 3)
    end
    for colname, _ in pairs(rowrep) do
      if not self:_columnexists(colname) then
        error("Trying to access nonexisting column in update function: " .. colname, 3)
      end
    end
    for col, val in pairs(rowrep) do
      row[col] = val
    end
    self.state.insync = false
    return true
  else
    error("Invalid type for SET argument: " .. type(set), 3)
  end
  return false
end,

--  t:UPDATE
-- { 
--     WHERE = {col1 = "asd", col2 = "3"}, --a nonexistent column here will result in an error
--     SET = {col2 = 4, col3 = "asdasd"}
-- }
--  t:UPDATE
-- { 
--     WHERE = function(row) return row.col1 == "asd" and row.col2 == "3" end, --optional
--     SET = function(row) row.col2 = 4 row.col3 = "asdasd" end
-- }
 UPDATE = function(self, args)
    if not args or type(args)~='table' then error("invalid arguments given: " .. tostring(args), 2) end
    if not args.SET or (type(args.SET)~='table' and type(args.SET)~='function') then
      error("Invalid SET argument: " .. tostring(args.SET))
    end
    if args.WHERE and type(args.WHERE)~='table' and type(args.WHERE)~='function' then
      error("Invalid WHERE argument: " .. tostring(args.WHERE))
    end

    local updated = 0
    for linenum, row in pairs(self.state.data) do
      if self:_match(args.WHERE, row) then
        if self:_update(args.SET, row) then 
          updated = updated + 1 
        end
      end
    end

    self:_syncifnecessary()
    return updated
 end,

 SELECT = function(self, args)
  if not args or type(args)~='table' then error("invalid arguments given: " .. tostring(args), 2) end
  if not args.WHERE or (type(args.WHERE)~='table' and type(args.WHERE)~='function') then
    error("Invalid WHERE argument!")
  end

  local ret = {}
  for linenum, row in pairs(self.state.data) do
    if self:_match(args.WHERE, row) then
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
  return self:_columnexists(colname)
end,

COLUMNCOUNT = function(self)
  return #(self:COLUMNS())
end,

ROWCOUNT = function(self)
  return #(self.state.data)
end,

 CLEAR = function(self)
  self.state.data = {}
  self.state.columns = {}
  self.state.wasnewcreated = true
  self.state.insync = false
  self:_syncifnecessary()
 end
}
return esitbllib


