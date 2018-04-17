-- esi-tables
local esitbllib =
{
    toolib = require'inmation.Toolbox',
    strlib = require'inmation.String',
    catlib = require'inmation.ESI.Catalog',
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

  state =
  {
      mode = "persistoncommand", --or "persistimmediately"
      holderobj = {},
      data = {},
      columns = {},
      insync = false,
      columnswritten = false
  },

  isempty = function(self)
    return #(self.state.data)==0
  end,

  synctoimage = function(self)
    self.state.holderobj.TableData = data
    self.state.holderobj:commit()
  end,

  syncfromimage = function(self)
    self.state.data = self.state.holderobj.TableData
    self.state.columns = {}


    for col, val in pairs(self.state.data[1]) do
        self.state.columns[col] = true
    end
    self.state.insync = true
  end,

  columnexists = function(self, colname)
    if not self.state.insync then
        self:syncfromimage()
    end
    return self.state.columns[colname]
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

    self.state.tableholderobj = o

    if args.mode and args.mode~="persistoncommand" then
        self.state.mode = "persistimmediately"
    end

    if not newcreated then
        self:syncfromimage()
    end

 end,



 SAVE = function(self)  
    self:synctoimage()
 end, 

 --t:ADDCOLUMNS{"col1","col2", "col3"}
 ADDCOLUMNS = function(self, args)
    if not args or type(args)~='table' then error("invalid arguments given: " .. tostring(args)) end

    --if empty, example:
    data["Tags"] = {}
    inmation.setvalue(o:path() .. '.TableData', self.json.encode({data = data}))
end, 

 REMOVECOLUMNS = function(self, args)
    if not args or type(args)~='table' then error("invalid arguments given: " .. tostring(args)) end  

 end, 

 ADDROW = function(self, args)
    if not args or type(args)~='table' then error("invalid arguments given: " .. tostring(args), 2) end

 end,

 UPDATE = function(self, args)
    if not args or type(args)~='table' then error("invalid arguments given: " .. tostring(args), 2) end
 end,

 CLEAR = function(self)

 end
}
return esitbllib


