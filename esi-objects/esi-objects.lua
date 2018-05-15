-- esi-objects
local mod = {}
local JSON = require 'dkjson'

--properties deciding about subobject types or mandatory properties have to bet set first!
--and can only be set at object creation
mod._priority =
{
  [".ChartType"] = 1, 
  [".ObjectName"] = 2,
  [".ItemID"] = 3,
  [".GenerationType"] = 4
}

function mod:INFO()
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
end


mod.log = {}

function mod:_log(mess)
  table.insert(self.log, mess)
end

--returns an iterator 
--returns only the critical properties if args.importantonly is set (properties who need to be set before first commit)
--otherwise only non-critical properties are returned by the iterator which can be set after object creation
--objectname belongs to both categories (has to be set before first commit but can also bet set at runtime)
function mod:_properties(kv, args)
  -- collect the keys
  local keys = {}
  for k in pairs(kv) do 
    if args and args.importantonly then
      if self._priority[k] then
        keys[#keys+1] = k --add only priorized keys
      end
    else
      if not self._priority[k] then
        keys[#keys+1] = k --add only non priorized keys
      end
    end
  end

  --add object name anyway
  if not (args and args.importantonly) then
    table.insert(keys, ".ObjectName")
  end

  --sort by priority number
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
end

function mod:_sortedpairs(kv, order)
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
end

--helper for tryapply
--compares the current value of the property with the value to set
function mod:_equal(v1, v2)
  if type(v1) == type(v2) and type(v1) ~= "table" then
    local t1 = tostring(v1)
    local t2 = tostring(v2)
    local res = v1 == v2
    self:_log("property type " .. type(t1) .. ", has value: " .. t1 .. ", to be: " .. t2 .. ", equality: " .. tostring(res))
    return v1 == v2
  elseif type(v1) == "table" and type(v2) == "table" then
    local t1, t2, res
    local ok, res = pcall(function()
        t1 = table.concat(v1)
        t2 = table.concat(v2)
        res = t1 == t2
        return res
      end)
    if ok then
      self:_log("table property detected, has value: " .. t1 .. ", to be: " .. t2 .. ", equality: " .. tostring(res))
      return res
    else
      error("these tables cannot be compared due to error " .. tostring(res))
    end
  elseif type(v1) ~= type(v2) then
    local t1, t2, res 
    local ok, res = pcall(function()
        t1 = tostring(v1)
        t2 = tostring(v2)
        res = t1 == t2
        return res
      end)
    if ok then
      self:_log("table property detected, has value: " .. t1 .. ", to be: " .. t2 .. " equality: " .. tostring(res))
      return res
    else
      error("these values cannot be compared due to error " .. res)
    end
  end
end

--helper for setproperty
function mod:_tryapply(o, name, val)
  local t = {}
  self:_log("setting property " .. tostring(name))
  for i in string.gmatch(name, "%a+") do
    table.insert(t, i)
  end
  if #t == 1 then
    if not self:_equal(o[t[1]], val) then
      o[t[1]] = val
      return true
    else
      return false
    end
  elseif #t == 2 then
    if not self:_equal(o[t[1]][t[2]], val) then
      o[t[1]][t[2]] = val
      return true
    else
      return false
    end
  elseif #t == 3 then
    if not self:_equal(o[t[1]][t[2]][t[3]], val) then
      o[t[1]][t[2]][t[3]] = val
      return true
    else
      return false
    end
  elseif #t == 4 then
    if not self:_equal(o[t[1]][t[2]][t[3]][t[4]], val) then
      o[t[1]][t[2]][t[3]][t[4]] = val
      return true
    else
      return false
    end
  end
  return false
end


--tries to set the property with name "name" to value "value"
--even works for "table-like" properties object.a.b.c = "asd" with property name "a.b.c"
--returns true if the object was changed (some value was inserted/changed)
--otherwise false
function mod:_setproperty(o, name, val)
  local changed = false
  if tonumber(val) then --this is new
    val = tonumber(val)
  end
  local ok, res = pcall(function() changed = self:_tryapply(o, name, val) return true end)
  if ok then
    if changed then
      self:_log("property value was changed!")
    end
    return changed
  else
    error("Could not set property " .. name .. " to value " .. JSON.encode(val) .. " due to error " .. res)
  end
end


--properties is a table
--    properties =
--   {
--     ["customkey"] = "customvalue",
--     ["customkey1"] = "customvalue1"
--   }
function mod:_setcustomproperties(o, properties)
  local changed = false
  for customkey, customvalue in pairs(properties) do
    self:_log("Trying to set custom property " .. tostring(customkey) .. " to value " .. tostring(customvalue))
    local thischanged = self:_setcustom(o, customkey, customvalue, true)
    changed = changed or thischanged
    if thischanged then
      self:_log("property value was changed!")
    end
  end
  return changed
end



function mod:_createobject(args)
  local ok, err = pcall(function()
      o = inmation.createobject(args.path, args.class)
    end)
  if not ok then 
    error("Could not create object with name " .. args.properties[".ObjectName"] .. " and class " .. args.class .. " at path " .. tostring(args.path) .. " due to error " .. err, 3)
  end
  local set = {}
  for key, value in self:_properties(args.properties, {importantonly = true}) do
    local ok, err = pcall(function()
        self:_log("(before first commit): Trying to set critical property " .. tostring(key) .. " to value " .. tostring(value))
        self:_setproperty(o, key, value)
        set[key] = value
      end)
  end

  local ok, err = pcall(function() o:commit() end)
  if not ok then
    local mess = [[Could not commit object at creation due to error %s, most likely a mandatory property
    or a property deciding about the subobject type is missing in the table 'priority' in line 8
    of this library, until now the following critical properties were set: %s]]
    local s = JSON.encode(set)
    error(mess:format(err, s))
  end

  for key, value in self:_properties(args.properties, {importantonly = false}) do
    local ok, err = pcall(function()
        self:_log("(on object creation): Trying to set critical property " .. tostring(key) .. " to value " .. tostring(value))
        self:_setproperty(o, key, value)
      end)
  end
  o:commit()
  return o
end


function mod:UPSERTOBJECT(args)
  self.log = {}
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
  if args.numid and not tonumber(args.numid) then
    error("Invalid numid argument passed! type " .. type(args.numid))
  end
  args.numid = tonumber(args.numid)

  --stores creationdetails
  local newcreated = false
  local exists, o = self:EXISTS{parentpath=args.path, objectname=args.properties[".ObjectName"], numid = args.numid} --if numid passed, numid has prevalence before objectname!
  if not exists then
    --create the object but do only set critial properties, commit once afterwards
    o = self:_createobject(args)
    self:_log("Object was new created at path " .. tostring(args.path))
    newcreated = true
  else
    self:_log("Object existed before")
  end



  local retrycounter = 0
  ::retry::
  local changed = false
  local fails = false
  local success = {}
  local errs = {}
  self:_log("Starting to upsert properties... ")
  for key, value in self:_properties(args.properties) do
    if not (tostring(key):lower() == "custom") then --string.find(key, "%.") and 
      local ok, err = pcall(
        function()
          self:_log("Trying to set property " .. tostring(key) .. " to value " .. tostring(value))
          local thischanged = self:_setproperty(o, key, value)
          if thischanged == true then
            self:_log("Property change detected!")
          end
          changed = changed or thischanged
        end)
      if not ok then
        local m = "Could not set property " .. tostring(key) .. " to value " .. tostring(value) .. " due to error " .. tostring(err)
        table.insert(errs, m)
        fails = true
      else
        success[key] = true
      end
    elseif tostring(key):lower() == "custom" then
      local ok, err = pcall(function()
        self:_log("Starting to upsert custom properties...")
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
  -- if fails and retrycounter <= 1 then
  --   retrycounter = retrycounter + 1
  --   goto retry
  -- elseif fails and retrycounter<=2 then
  --   local ok, err = pcall(function() o:commit() end)
  --   retrycounter = retrycounter + 1
  --   goto retry
  -- else
  if fails then -- and retrycounter>2 
    --DEBUG
    local props = JSON.encode(args.properties)
    local name = o.ObjectName or "NIL"
    local succ = JSON.encode(success)
    local e = JSON.encode(errs)

    local mess = "Could not upsert object! Properties: %s, ObjectName: %s, successful property set after creation: %s errors: %s"
    mess = mess:format(props, name, succ, e)
    error(mess, 2)
  end

  if changed then
    local ok, err = pcall(function() o:commit() end)
    if not ok then
      --DEBUG
      local props = JSON.encode(args.properties)
      local name = o.ObjectName or "NIL"
      local errs = JSON.encode(errs)
      local succ = JSON.encode(success)

      local mess = "Could not upsert object! Properties: %s, Errors: %s, ObjectName: %s, Successful Property Writes: %s"
      mess = mess:format(props, errs, name, succ)
      error(mess, 2)
    end
  end



  return o, changed, newcreated
end

function mod:GETLOG()
  return JSON.encode(self.log)
end

--returns true, object, namechanged
--namechanged can only be returned if a numid is given additionally
function mod:EXISTS(args)
  if args.path then
    if type(args.path)~='string' then
      error("invalid type for field path: " .. type(string), 2)
    end
    local o = inmation.getobject(args.path)
    if o then
      return true, o
    else
      return false
    end
  elseif args.parentpath and args.objectname then
    if type(args.parentpath) ~= "string" then
      error("invalid type for parentpath: " .. type(args.parentpath), 2)
    end
    if type(args.objectname) ~= "string" then
      error("invalid type for objectname: " .. type(args.objectname), 2)
    end
    local parent = inmation.getobject(args.parentpath)
    if not parent then
      return false
    end
    --parent exists -> check existence of numid at this path
    if args.numid and type(args.numid) == "number" then
      local o = inmation.getobject(args.numid)
      if o and o:parent():path() == args.parentpath then
        local namechanged = o.ObjectName ~= args.objectname
        return true, o, namechanged
      else
        return false
      end
    end
    --no numid given, parent exists -> check for object name at this parentpath
    local o = inmation.getobject(args.parentpath .. "/" .. args.objectname)
    if not o then
      return false
    end
    return true, o
  end
  if not args.object then 
    return false 
  else
    local obj
    local ok, err = pcall(function() obj = inmation.getobject(args.object:path()) end)
    if not ok then return false end
    return true, obj
  end
end

--kvtab is a table whose keys and values are strings!
function mod:_upsertcustom(obj, kvtab, allownewkey)
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
      if tostring(requiredval) ~= tostring(custvalues[n]) then
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
end

function mod:GETCUSTOM(args)
  if not args then
    error("arguments are empty!", 2)
  end
  if not args.object then
    error("field 'object' is not existent in the args table!", 2)
  end
  if not self:EXISTS{object = args.object} then
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
end


function mod:SETCUSTOM(args)
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
  if not self:EXISTS{object = args.object} then
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
end

function mod:SORTCUSTOM(args)
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


  ----implement sorting
  error("Not implemented yet!")

end
return mod