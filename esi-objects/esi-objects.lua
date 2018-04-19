-- esi-objects
local mod =
{
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
      modulename = "esi-objects",
      dependencies = {
        {
          modulename = 'dkjson',
          version = {
            major = 2,
            minor = 5,
            revision = 0
          }
        },
      }
    }
  }
end,


  JSON = require 'dkjson',
  
  --properties deciding about subobject types or mandatory properties have to bet set first!
  _priority =
    {
      [".ChartType"] = 1, 
      [".ObjectName"] = 2,
      [".ItemID"] = 3
    },

  _properties = function(self, kv, args)
		-- collect the keys
		local keys = {}
    for k in pairs(kv) do 
      if args.importantonly then
        if self._priority[k] then
          keys[#keys+1] = k --add only priorized keys
        end
      else
        if not self._priority[k] then
          keys[#keys+1] = k --add only non priorized keys
        end
      end
    end
    table.sort(keys, function(a,b)
      if self._priority[a] and self._priority[b] then
        return self._priority[a] < self._priority[b]
      end
      return #a<#b
    end)
		-- return the iterator function
		local i = 0
		return function()
			i = i + 1
			if keys[i] then
				return keys[i], kv[keys[i]]
			end
		end
	end,

  _sortedpairs = function(self, kv, order)
		-- collect the keys
		local keys = {}
		for k in pairs(kv) do keys[#keys+1] = k end
		-- if order function given, sort by it by passing the table and keys a, b,
	    -- otherwise just sort the keys 

		if order and type(order)=="function" then
			table.sort(keys, function(a,b) return order(t, a, b) end)
		else
      table.sort(keys, function(a,b)
        if self._priority[a] and self._priority[b] then
          return self._priority[a] < self._priority[b]
        end
        if self._priority[a] and not self._priority[b] then
          return true
        end
        if not self._priority[a] and self._priority[b] then
          return false
        end
        return #a<#b
      end)
		end

		-- return the iterator function
		local i = 0
		return function()
			i = i + 1
			if keys[i] then
				return keys[i], kv[keys[i]]
			end
		end
	end,

  --helper for tryapply
  --compares the read property with the written property
  _equal = function(v1, v2)
    if type(v1)==type(v2) and type(v1)~="table" and type(v2)~="table" then
      return tostring(v1)==tostring(v2)
    elseif type(v1)=="table" and type(v2)=="table" then
      local ok, res = pcall(function()
          local t1 = table.concat(v1)
          local t2 = table.concat(v2)
          return tostring(t1)==tostring(t2)
        end)
      if ok then
        return res
      else
        error("these tables cannot be compared due to error " .. res)
      end
    elseif type(v1)~=type(v2) then
      local ok, res = pcall(function()
          local t1 = tostring(v1)
          local t2 = tostring(v2)
          return tostring(t1)==tostring(t2)
        end)
      if ok then
        return res
      else
        error("these values cannot be compared due to error " .. res)
      end
    end
  end,

  --helper for setproperty
  _tryapply = function(self, o, name, val)
    local t = {}
    for i in string.gmatch(name, "%a+") do
      table.insert(t, i)
    end
    if #t == 1 then
        if not self._equal(o[t[1]], val) then
            o[t[1]] = val
            return true
        else
            return false
        end
    elseif #t == 2 then
        if not self._equal(o[t[1]][t[2]], val) then
            o[t[1]][t[2]] = val
            return true
        else
            return false
        end
    elseif #t == 3 then
        if not self._equal(o[t[1]][t[2]][t[3]], val) then
            o[t[1]][t[2]][t[3]] = val
            return true
        else
            return false
        end
    elseif #t == 4 then
        if not self._equal(o[t[1]][t[2]][t[3]][t[4]], val) then
            o[t[1]][t[2]][t[3]][t[4]] = val
            return true
        else
            return false
        end
    end
    return false
end,


--tries to set the property with name "name" to value "value"
--even works for "table-like" properties object.a.b.c = "asd"
--returns true if the object was changed (some value was inserted)
--otherwise false
_setproperty = function(self, o, name, val)
  local ok, res = pcall(function() return self:_tryapply(o, name, val) end)
  if ok then
    return res
  else
    error("Could not set property " .. name .. " to value " .. self.JSON.encode({value = val}) .. " due to error " .. res)
  end
end,


--properties is a table
--    properties =
--   {
--     ["customkey"] = "customvalue",
--     ["customkey1"] = "customvalue1"
--   }
_setcustomproperties = function(self, o, properties)
  local changed = false
  for customkey, customvalue in pairs(properties) do
    changed = changed or self:_setcustom(o, customkey, customvalue, true)
  end
  return changed
end,



_createobject = function(self, args)
  local ok, err = pcall(function()
    o = inmation.createobject(args.path, args.class)
  end)
  if not ok then 
    error("Could not create object with name " .. args.properties[".ObjectName"] .. " and class " .. args.class .. " at path " .. tostring(args.path) .. " due to error " .. err, 3)
  end
  if o == nil then
    error("unexpected error, object of type " .. objtype .. " at path " .. pa .. " was not created! ObjectName " .. name)
  end
  for key, value in self:_properties(args.properties, {importantonly=true}) do
    local ok, err = pcall(function()
      self:_setproperty(o, key, value)
    end)
  end

  local ok, err = pcall(function() o:commit() end)
  if not ok then
    local mess = [[Could not commit object due to error %s, most likely a mandatory property
    or a property deciding about the subobject type is missing in the table 'priority' in line 8
    of this library]]
    error(mess:format(err))
  end

  for key, value in self:_properties(args.properties, {importantonly=false}) do
    local ok, err = pcall(function()
      self:_setproperty(o, key, value)
    end)
  end
  o:commit()
  return o
end,


--[[@md
### UPSERTOBJECT

Upserts an object with minimal required count of commits.

```lua
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
```lua

@md]]
UPSERTOBJECT = function(self, args)
  if not args.path then
    error("path field is empty!", 2)
  end
  if not type(args.path)=="string" then
    error("invalid type for path field!", 2)
  end
  if not args.properties then
    error("the properties field is empty!", 2)
  end
  if not args.properties[".ObjectName"] then
    error("no object name is provided!" , 2)
  end
  if type(args.properties[".ObjectName"])~="string" then
    error("invalid type for ['ObjectName']! type " ..  type(args.properties[".ObjectName"]), 2)
  end
  if type(args.properties)~="table" then
    error("invalid type for properties! type " ..  type(args.properties), 2)
  end
  if not self:EXISTS({path=args.path}) then
    error("the parent object does not exist! path " .. args.path, 2)
  end
  if not args.class then
    error("no object class was provided!", 2)
  end
  if type(args.class)~="string" then
    error("invalid type for object class! type " .. type(args.class), 2)
  end

  local newcreated = false
  local exists, o = self:EXISTS{parentpath=args.path, objectname=args.properties[".ObjectName"]}
  if not exists then
    o = self:_createobject(args)
    newcreated = true
  end


  
  local retrycounter = 0
  ::retry::
  local changed = false
  local fails = false
  local success = {}
  local errs = {}
  for key, value in self:_sortedpairs(args.properties) do
    if not string.find(key:lower(), "custom") then --string.find(key, "%.") and 
      local ok, err = pcall(function()
          changed = changed or self:_setproperty(o, key, value)
        end)
        if not ok then
          local m = "Could not set property " .. tostring(key) .. " to value " .. tostring(value) .. " due to error " .. err
          table.insert(errs, m)
          fails = true
        else
          success[key] = true
        end
    elseif tostring(key) == "Custom" then
      local ok, err = pcall(function()
          changed = changed or self:_upsertcustom(o, value, true)
        end)
        if not ok then
          local m = "Could not set property " .. tostring(key) .. " to value " .. tostring(value) .. " due to error " .. err
          table.insert(errs, m)
          fails = true
        else
          success[key] = true
        end
    else
      error("invalid key: " .. tostring(key), 2)
    end
  end
  if fails and retrycounter <= 1 then
    retrycounter = retrycounter + 1
    goto retry
  elseif fails and retrycounter<=2 then
    local ok, err = pcall(function() o:commit() end)
    retrycounter = retrycounter + 1
    goto retry
  elseif fails and retrycounter>2 then
    --DEBUG
    local props = self.JSON.encode(args.properties)
    local name = o.ObjectName or "NIL"
    local errs = self.JSON.encode(errs)
    local succ = self.JSON.encode(success)

    local mess = "Could not upsert object! Properties: %s, Errors: %s, ObjectName: %s, Successful Property Writes: %s"
    mess = mess:format(props, errs, name, succ)
    error(mess, 2)
  end
  
  if changed then
    local ok, err = pcall(function() o:commit() end)
    if not ok then
      error("Could not commit object due to error " .. err, 2)
    end
  end



  return o, changed, newcreated
end,


EXISTS = function(self, args)
  if args.path then
    if type(args.path)~='string' then
      error("invalid type for field path: " .. type(string))
    end
    local o = inmation.getobject(args.path)
    if o then
      return true, o
    else
      return false
    end
  else
    if args.parentpath and args.objectname then
      if type(args.parentpath)~="string" then
        error("invalid type for parentpath: " .. type(parentpath))
      end
      if type(args.objectname)~="string" then
        error("invalid type for objectname: " .. type(parentpath))
      end
      local parent = inmation.getobject(args.parentpath)
      if not parent then
        return false
      end
      local o = inmation.getobject(args.parentpath .. "/" .. args.objectname)
      if not o then
        return false
      end
      return true, o
    end
  end
  if args.object then
    local obj
    local ok, err = pcall(function() local obj = inmation.getobject(args.object:path()) end)
    if not ok then return false end
    return true
  end
end,

--kvtab is a table whose keys and values are strings!
upsertcustom = function(self, obj, kvtab, allownewkey)
  local custkeys, custvalues
  local ok, err = pcall(function()
      custkeys = obj.CustomOptions.CustomProperties.CustomPropertyName
      custvalues = obj.CustomOptions.CustomProperties.CustomPropertyValue
    end)
  if not ok then
    error("could not access custom properties of object " .. obj:path() .. " due to error " .. err, 3)
  end

  local changed = false
  --1: iterate over custom keys existing in the object and update their values if necessary
  for n = 1, #custkeys do --iterate over all existing keys
    local custkey = custkeys[n]
    local requiredval = kvtab[tostring(custkey)]
    if requiredval then
      if tostring(requiredval)~=tostring(custvalues[n]) then
        custvalues[n] = tostring(requiredval)
        changed = true
      end
    end
    --remove this pair from the table since it was updated
    kvtab[tostring(custkey)] = nil
  end

  for newkey, newvalue in pairs(kvtab) do
    if not allownewkey then
      error("Creation of new keys was not allowed! Could not create key " .. key .. " for object " .. obj:path())
    end
    changed = true
    table.insert(custkeys, newkey)
    table.insert(custvalues, newvalue)
  end
  obj.CustomOptions.CustomProperties.CustomPropertyName = custkeys
  obj.CustomOptions.CustomProperties.CustomPropertyValue = custvalues

  if changed then
    local ok, err = pcall(function() obj:commit() end)
    if not ok then
      error("Could not commit custom property changed due to error " .. err)
    end
  end
  return changed
end,


--[[@md
### GETCUSTOM

Gets a custom property

```lua
O:SETCUSTOM{object = o, key = "asd", value = "v"}
O:SETCUSTOM{object = o, key = {"asd1", "asd2"}, value = {"v1", "v2"}}
```lua
@md]]
GETCUSTOM = function(self, args)
    if not args then
        error("arguments are empty!", 2)
    end
    if not args.object then
        error("field 'object' is not existent in the args table!", 2)
    end
    if not self:EXISTS(args.object) then
        error("field 'object' does not hold a valid inmation object!", 2)
    end
    if not args.key then
        error("There are no custom key(s) given!", 2)
    end
    if type(args.key) ~= 'string' and type(args.key) ~= 'table' then
        error("Invalid type for key: " .. args.key:type())
    end
    local custkeys, custvalues
    local ok, err = pcall(function()
        custkeys = args.object.CustomOptions.CustomProperties.CustomPropertyName
        custvalues = args.object.CustomOptions.CustomProperties.CustomPropertyValue
        end)
    if not ok then
        error("could not access custom properties of object " .. obj:path() .. " due to error " .. err, 2)
    end

    local getvalue = function(key)
        for n = 1, #custkeys do
            if tostring(custkeys[n]) == tostring(key) then --keys are case sensitive!
                return tostring(custvalues[n])
            end
        end
        return nil
    end

    --only one key queried
    if type(args.key) == 'string' then
        return getvalue(args.key)
    end

    --multiple keys
    local vals = {}
    local nilkeys = {}
    if type(args.key) == 'table' then
        for _, key in ipairs(args.key) do
            local val = getvalue(key)
            if val then
                table.insert(vals, val)
            else
                table.insert(nilkeys, key)
            end
        end
        if nilkeys then
          return vals, nilkeys
        else
          return vals, nil
        end
    end
    return nil
end,

--[[@md
### SETCUSTOM

Sets a custom property

```lua
modLib:SETCUSTOM{object = obj, key = "asd", value = "asd",  disallownewkeys = false}
-- key and value always have to be strings!
modLib:SETCUSTOM{object = obj, key = {"asd1", "asd2"}, value = {"v1, v2"}}
```lua
@md]]
SETCUSTOM = function(self, args)
  --check arguments
  if not args then
    error("arguments are empty!", 2)
  end
  if type(args)~='table' then
    error("Invalid argument type!", 2)
  end
  if not args.object then
    error("field 'object' is not existent in the args table!", 2)
  end
  if not self:EXISTS(args.object) then
    error("field 'object' does not hold a valid inmation object!", 2)
  end
  if not args.key then
    error("There are no custom key(s) given!", 2)
  end
  if not args.value then
    error("There are no custom value(s) given!", 2)
  end
  if type(args.key) ~= 'string' and type(args.key) ~= 'table' then
    error("Invalid type for key: " .. type(args.key))
  end
  if type(args.value) ~= 'string' and type(args.value) ~= 'table' then
    error("Invalid type for key: " .. type(key))
  end
  if type(args.value) == 'table' and type(args.key) == 'table' and #args.value ~= #args.key
  then
    error("Key and value table need to have the same length! " .. #args.key .. " vs " .. #args.value, 2)
  end
  local createkeys = true
  if args.disallownewkeys then
    createkeys = false
  end

  --non-table keys/values
  if type(args.key) ~= 'table' and type(args.value) ~= 'table' then
    local ok, err = pcall(function() 
      self:_upsertcustom(args.object, {[args.key] = args.value}, createkeys) 
    end)
    if not ok then
      error("Could not set custom properties for object " .. args.object:path() .. ", error: " .. err)
    end
  end

  --table key/values
  local kvtab = {}
  for i=1, #(args.key) do
    if args.key[i] then
      kvtab[args.key[i]] = args.value[i]
    end
  end
  local ok, err = pcall(function() self:_upsertcustom(args.object, kvtab, createkeys)  end)
  if not ok then
    error("Could not set custom properties for object " .. args.object:path() .. ", error: " .. err, 2)
  end
end,


SORTCUSTOM = function(self, args)
  --check arguments
  if not args then
    error("arguments are empty!", 2)
  end
  if type(args)~='table' then
    error("Invalid argument type!", 2)
  end
  if not args.object then
    error("field 'object' is not existent in the args table!", 2)
  end
  if not self:EXISTS(args.object) then
    error("field 'object' does not hold a valid inmation object!", 2)
  end
  if not args.key then
    error("There are no custom key(s) given!", 2)
  end
  if not args.value then
    error("There are no custom value(s) given!", 2)
  end
  if type(args.key) ~= 'string' and type(args.key) ~= 'table' then
    error("Invalid type for key: " .. type(args.key))
  end
  if type(args.value) ~= 'string' and type(args.value) ~= 'table' then
    error("Invalid type for key: " .. type(key))
  end
  if type(args.value) == 'table' and type(args.key) == 'table' and #args.value ~= #args.key
  then
    error("Key and value table need to have the same length! " .. #args.key .. " vs " .. #args.value, 2)
  end
  local createkeys = true
  if args.disallownewkeys then
    createkeys = false
  end

  --non-table keys/values
  if type(args.key) ~= 'table' and type(args.value) ~= 'table' then
    local ok, err = pcall(function() 
      self:_upsertcustom(args.object, {[args.key] = args.value}, createkeys) 
    end)
    if not ok then
      error("Could not set custom properties for object " .. args.object:path() .. ", error: " .. err)
    end
  end

  --table key/values
  local kvtab = {}
  for i=1, #(args.key) do
    if args.key[i] then
      kvtab[args.key[i]] = args.value[i]
    end
  end
  local ok, err = pcall(function() self:_upsertcustom(args.object, kvtab, createkeys)  end)
  if not ok then
    error("Could not set custom properties for object " .. args.object:path() .. ", error: " .. err, 2)
  end
end,
}
return mod