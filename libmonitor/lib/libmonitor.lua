-- libmonitor
-- gets the libraries from all inmation items an return a table
local _checklibs = function(path, datatable)
	local o = inmation.getobject(path)
	local LuaModuleName = o.ScriptLibrary.LuaModuleName
	local AdvancedLuaScript = o.ScriptLibrary.AdvancedLuaScript
	for indexlua, modulename in ipairs(LuaModuleName) do
		local dependenciesruntime = {}
		local ok, content = pcall(function()
			local luascriptcontent = AdvancedLuaScript[indexlua]
			for reqlib in string.gmatch(luascriptcontent, "require'(%w+.%w+.%w+)'") do
				table.insert(dependenciesruntime, {LibraryName =reqlib})
			end
			local lib = load(luascriptcontent)()
			local info = {}
			if type(lib.INFO) == "function" then
				info = lib.INFO()
			end
			local version
			if type(lib.VERSION) == "function" then
				version = lib.VERSION()
			end
			return {["LuaModuleName"] = modulename,["INFO"] = {info}, VERSION= version,["runtime-dependencies"] = dependenciesruntime, path = o:path()} 
		end)
		if ok then
			table.insert( datatable, content)
		else
			table.insert( datatable, {["LuaModuleName"] = v,error= content, path = o:path() })
		end
	end
	return datatable
end

local libmonitor =
{
	INFO = function()
		return {
			version = {
        		major = 0,
            	minor = 1,
            	revision = 5
          	},
        	contacts = {
        		{
              		name = "Florian Seidl",
              		email = "florian.seidl@cts-gmbh.de"
            	},
          	},
        	library = {
        		modulename = "libmonitor",
				dependencies = {
					{ 
						modulename= "dkjson",
						version = {
							major = 2,
							minor = 5,
							revision = 0
						},
					},
					{
						modulename= "inmation.Catalog",
						version = {
							major = 0,
							minor = 0,
							revision = 0
						},
					}
				},
			},
        }
	end,
	-- @md
	getalllibs = function (arg)
		local J = require'dkjson'
		local C = require'inmation.Catalog' --todo: replace with esi-catalog
		local data = {}
		local objects = C:filterByPropValue({ "LuaModuleName"}, { "%%"}, { "LIKE" })
		local pathdone = {}
		for _,obj in ipairs(objects) do
			local path = obj:path()
			if pathdone[path] == nil then
				data = _checklibs(path, data)
				pathdone[path] = true
			end
		end

		local msg = {}
		msg.topic = 'json'
		msg.payload = J.encode(data)
		msg.headers = {
			["Content-Type"] = "application/json"
		}
		return msg
	end,
}
return libmonitor