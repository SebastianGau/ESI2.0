-- esi-variables
local esivariables = -- note: local scope COMPULSORY here
{
--[[@md 
### INFO

This is a mandatory function for every ESI library.

Usage

```lua
    local JSON = require('dkjson')
    local ESI = require('esi-example')
    local result = ESI:INFO()
    error(JSON.encode(result))
```

Example response

```lua
ommited for brevity
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
        modulename = "esi-variables",
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
            modulename = 'inmation.String',
            version = {
              major = 0,
              minor = 1,
              revision = 1
            }
          }
        }
      }
    }
  end,

  json = require'dkjson',
  O = require 'esi-objects',
  strlib = require'inmation.String',

--[[@md 
### SETVARIABLE

Upserts a variable underneath the code-executing object and sets its value. Tables are automatically converted to json.

```lua
SETVARIABLE(path, v, q, t)
SETVARIABLE({path ="aas", v=1.4, q=1,t=2348763284767})
SETVARIABLE({path ="aas", v=1.4, q=1,t=2348763284767, json = {indent = true}})
SETVARIABLE({object = obj, path ="aas", v=1.4, q=1,t=2348763284767, json = {indent = true}})
```
@md]]
SETVARIABLE = function(self, ...)
  local J = self.json
  local ObjectParent, ObjectName = ""
  local variablepath = nil
  local v = nil
  local q = nil
  local t = nil
  local obj = inmation.getself()
  local args = table.pack(...)
  if #args > 1 then
    variablepath = args[1]
    if type(args[2]) == "table" then
      v = J.encode(args[2], {indent = false})
    else
      v = args[2]
    end
    q = args[3]  or 0
    t = args[4] or inmation.currenttime()
  elseif #args == 1 then
    variablepath = args[1].path
    if type(args[1].v) == "table" then
      local jsonprop = args[1].json or {indent = false}
      v = J.encode(args[1].v, jsonprop)
    else
      v = args[1].v
    end
    q = args[1].q or 0
    t = args[1].t or inmation.currenttime()
    obj = args[1].object or obj
  else
    return false
  end
  if variablepath then
    ObjectParent,ObjectName = inmation.splitpath(variablepath)
    if ObjectName == nil then
      ObjectName = variablepath
      ObjectParent = ""
    end
  else
    return false
  end
  local selfpath = obj:path()
  if #ObjectParent > 0 then
    for _,vgroup in ipairs(inmation.split(ObjectParent, "/")) do
      if self.O:EXISTS{["parentpath"] = selfpath, ["objectname"] = vgroup} == false then
        local variablegrpprop = {
          ["path"] = selfpath,
          ["class"] = "MODEL_CLASS_VARIABLEGROUP",
          ["properties"] = {
            [".ObjectName"] = vgroup
          }
        }
        --self:createobject(variablegrpprop)
        self.O:UPSERTOBJECT(variablegrpprop)
      end
      selfpath = selfpath .. "/" .. vgroup
    end
  end
  if self.O:EXISTS{["parentpath"] = selfpath, ["objectname"] = ObjectName} == false then
    local variableprop = {
      ["path"] = selfpath,
      ["class"] = "MODEL_CLASS_VARIABLE",
      ["properties"] = {
        [".ObjectName"] = ObjectName,
        [".ArchiveOptions.StorageStrategy"] = inmation.model.flags.ItemValueStorageStrategy.STORE_RAW_HISTORY,
        [".ArchiveOptions.ArchiveSelector"] = inmation.model.codes.ArchiveTarget.ARC_PRODUCTION,
        [".ArchiveOptions.PersistencyMode"] = inmation.model.codes.PersistencyMode.PERSIST_PERIODICALLY,
      }
    }
    self:createobject(variableprop)
  end
  inmation.setvalue(selfpath .. "/" .. ObjectName, v, q, t)
  return true
end,


--[[@md
### GETVARIABLE

Retrieves a variable value from underneath the code-executing object.

```lua
local v,q,t = O:GETVARIABLE(variablepath)
local v,q,t = O:GETVARIABLE{ path ="aas"}
local v,q,t = O:GETVARIABLE{object = obj, path ="aas"}
```
@md]]
GETVARIABLE = function(self, arg)
  local J = self.json
  local obj = inmation.getself()
  local path = nil
  if type(arg) == "table" then
    local variablepath = arg.path
    obj = arg.object or obj
    path = obj:path() .. "/" .. variablepath
  elseif type(arg) == "string" then
    path = obj:path() .. "/" .. arg
  else
    return nil,nil,nil
  end
  if self.O:EXISTS{["path"] = path} == false then
    return nil,nil,nil
  else
    local v,q,t = inmation.getvalue(path)
    if type(v) == "string" then
      if v:sub(1,1) .. v:sub(-1,-1) == "{}" or v:sub(1,1) .. v:sub(-1,-1) == "[]" then
        local vj = J.decode(v) or v
        return vj,q,t
      end
    end
    return v,q,t
  end
end,
}
return esivariables
