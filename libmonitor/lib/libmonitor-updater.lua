-- libmonitor-updater
libmonitor =
{
	INFO = function()
        return {
			version = {
				major = 0,
				minor = 0,
				revision = 1
			},
			contacts = {
				{
					name = "Florian Seidl",
					email = "florian.seidl@cts-gmbh.de"
				},
			},
			library = {
				modulename = "libmonitor-updater",
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
						modulename= "esi-objects",
						version = {
							major = 0,
							minor = 1,
							revision = 1
						},
					},
					{
						modulename= "esi-variables",
						version = {
							major = 0,
							minor = 1,
							revision = 2
						},
					}
				},
			},
		}
	end,
	JSON = require'dkjson',
	ESIOBJLIB = nil,
	ESIVARLIB = nil,
	--
	log = {messages = {},call={}},
	debugging = false,
	deploymentScope = {
		["System"] = inmation.getsystempath(),
		["Core"] = inmation.getcorepath()
	},
	--
	_checkEssentialLibrary = function(self, arg)
		local ok, lib = pcall(function()
			return require(arg.name)
		end)
		if ok == false then
			self:_checklibrary(arg)
		end
		return require(arg.name)
	end,
	--@md  checkForUpdates
	CHECKFORUPDATES = function(self)
		local rt = inmation.now()
		self.log = {messages = {},call={}}
		-- special initial for required libraries to download them, when thy not exists
		self.ESIOBJLIB = self:_checkEssentialLibrary{name = "esi-objects", url = "https://raw.githubusercontent.com/SebastianGau/ESI2.0/master/esi-objects/esi-objects.lua",scope = "System"}
		self.ESIVARLIB = self:_checkEssentialLibrary{name = "esi-variables", url = "https://raw.githubusercontent.com/SebastianGau/ESI2.0/master/esi-variables/esi-variables.lua",scope = "System"}
		-- special initial end
		local O = self.ESIOBJLIB
		local V = self.ESIVARLIB
		-- todo: self:_logmessage("Start")
		self:_logmessage("Start CHECKFORUPDATES")
		local parentpath = self.rootpath or inmation.getparentpath(inmation.getselfpath())
		local selfobj = inmation.getself()
        local objectname = selfobj.ObjectName .. " Repository Table"
        local exists, tableholder = O:EXISTS{ ["parentpath"] = parentpath, ["objectname"] = objectname }
        if exists == false then
			tableholder = O:UPSERTOBJECT{path = parentpath, class = "MODEL_CLASS_TABLEHOLDER", properties = {[".ObjectName"] = objectname,
			}}
            tableholder.TableData = '{  "data": {    "name": [      ],    "url": [      ],    "scope": [      ]  }}'
            tableholder:commit()
        end
		local libraries = tableholder.TableData
		for _,library in pairs(libraries) do
			self:_checklibrary(library)
		end
		self:_logmessage("CHECKFORUPDATES completed. Runtime " .. inmation.now() -rt .. "ms")
		V:SETVARIABLE("Log/message", self.log )
		V:SETVARIABLE("PerformanceCounter/runtime", inmation.now() -rt)
		return true
	end,
	--self:_checklibrary(tablerow)
	_checklibrary = function(self, arg)
		self:_logmessage("Start CHECKFORUPDATES", arg)
		local V = self.ESIVARLIB
		call = {
			url = arg.url,
			method = "GET",
		}

		local lib = self:_webcall(call)
		local ok, libinfo = self:_checklib(lib)
		if ok then
			self:_ensureLibrary{LibraryInfo = libinfo, Scope = arg.scope}
		else
			self:_logmessage("_checklib failed: " .. arg.name .. ": " .. libinfo, arg)
		end
	end,
	-- self:_ensureLibrary{LibraryInfo = libinfo, Scope = "System"}
	_ensureLibrary = function(self, arg)
		--local V = self.ESIVARLIB
		self:_logmessage("Start _ensureLibrary: " .. arg.LibraryInfo.LuaModuleName)
		local libraryscope = self.deploymentScope[arg.Scope] or arg.Scope
		local libraryname = arg.LibraryInfo.LuaModuleName
		local librarycontent = arg.LibraryInfo.AdvancedLuaScript
		if type(libraryscope) == "string" and type(libraryname) == "string" then
			local o = inmation.getobject(libraryscope)
			local indexlibrary = nil
			for indexlua, modulename in ipairs(o.ScriptLibrary.LuaModuleName) do
				if modulename == libraryname then
					indexlibrary = indexlua
					break
				end
			end
			-- library not exists
			if type(indexlibrary) == "nil" then
				self:_logmessage("_ensureLibrary: add library " .. libraryname .. " to " .. o:path())
				local LuaModuleName = o.ScriptLibrary.LuaModuleName
				table.insert( LuaModuleName, libraryname)
				local AdvancedLuaScript = o.ScriptLibrary.AdvancedLuaScript
				table.insert( AdvancedLuaScript, librarycontent)
				local LuaModuleMandatoryExecution = o.ScriptLibrary.LuaModuleMandatoryExecution
				table.insert( LuaModuleMandatoryExecution, false)
				o.ScriptLibrary.LuaModuleName = LuaModuleName
				o.ScriptLibrary.AdvancedLuaScript = AdvancedLuaScript
				o.ScriptLibrary.LuaModuleMandatoryExecution = LuaModuleMandatoryExecution
				o:commit()
			elseif type(indexlibrary) == "number" then
				self:_logmessage("_ensureLibrary: library " .. libraryname .. " exists at " .. o:path() .. ", index :" .. indexlibrary)
				local LuaModuleName = o.ScriptLibrary.LuaModuleName
				local AdvancedLuaScript = o.ScriptLibrary.AdvancedLuaScript
				local LuaModuleMandatoryExecution = o.ScriptLibrary.LuaModuleMandatoryExecution
				--check if downloaded version is newer
				local runok, runinfo = self:_checklib(AdvancedLuaScript[indexlibrary])
				if runok then
					if runinfo.INFO.version.major < arg.LibraryInfo.INFO.version.major or runinfo.INFO.version.minor < arg.LibraryInfo.INFO.version.minor or runinfo.INFO.version.revision < arg.LibraryInfo.INFO.version.revision then
						self:_logmessage("_ensureLibrary: update library " .. libraryname .. " to " .. o:path(),{newINFO=arg.LibraryInfo.INFO , runINFO=runinfo.INFO.version})
						LuaModuleName[indexlibrary] = libraryname
						AdvancedLuaScript[indexlibrary] = librarycontent
						LuaModuleMandatoryExecution[indexlibrary] = false
						o.ScriptLibrary.LuaModuleName = LuaModuleName
						o.ScriptLibrary.AdvancedLuaScript = AdvancedLuaScript
						o.ScriptLibrary.LuaModuleMandatoryExecution = LuaModuleMandatoryExecution
						o:commit()
					else
						self:_logmessage("_ensureLibrary: library " .. libraryname .. " is up to date at " .. o:path(), {newINFO=arg.LibraryInfo.INFO.version , runINFO=runinfo.INFO.version})
					end
				else
					self:_logmessage("_ensureLibrary: _checklib " .. libraryname .. " failed: " .. runinfo)
				end
			end
		end
	end,
	-- check runtime error and returns the runtime information for library content
	_checklib = function(self, library)
		local dependenciesruntime = {}
		local ok, content = pcall(function()
			local luascriptcontent = library
			for reqlib in string.gmatch(luascriptcontent, "require'(%w+.%w+.%w+)'") do
				table.insert(dependenciesruntime, {LibraryName = reqlib})
			end
			local lib = load(luascriptcontent)()
			local info = {}
			if type(lib.INFO) == "function" then
				info = lib.INFO()
			end
			return {["LuaModuleName"] = info.library.modulename ,["INFO"] = info,["runtime-dependencies"] = dependenciesruntime, AdvancedLuaScript = luascriptcontent}
		end)
		return ok, content
	end,
	--Read over http-Interface
	_webcall = function(self, call)
		local tcall = inmation.now()
		local V = self.ESIVARLIB
		local J = self.JSON
		local ltn12 = require("ltn12")
		local localsocket = require "ssl.https"
		local method = call.method or "GET"
		local payload = call.payload or [[ {} ]]
		local user = call.user
		local password = call.password
		if type(payload) == "table" then
			payload = J.encode(payload)
		end
		local ResultTable = {}
		local url = call.url
		--local ResultTable = localsocket.request(url)
		local r1, status, content, result1, result2 = localsocket.request{["url"]=url,
			method = method,
			sink = ltn12.sink.table(ResultTable),
			source = ltn12.source.string(payload),
			headers =
			{
			-- ["Authorization"] = "Maybe you need an Authorization header?",
			["Content-Type"] = "application/json",
			["Content-Length"] = payload:len(),
			["username"] = user,
			["password"] = password
			},
		}
		if self.debugging and type(V) ~= "nil" then
			V:SETVARIABLE("debug/call/url",url)
			V:SETVARIABLE("debug/call/r1",r1)
			V:SETVARIABLE("debug/call/result1",result1)
			V:SETVARIABLE("debug/call/result2",result2)
			V:SETVARIABLE("debug/call/ResultTable",ResultTable)
			V:SETVARIABLE("debug/call/ResultTable type",type(ResultTable))
			V:SETVARIABLE("debug/call/status",status)
			V:SETVARIABLE("debug/call/content",content)
		end
		if type(ResultTable) == "table" then
			ResultTable = table.concat(ResultTable)
		end
		table.insert( self.log.call, {["time"] = inmation.now() - tcall,["url"] = url})
		return ResultTable
	end,
	-- @md
	DEBUGGING = function(self, value)
		self.debugging = value
	end,
	--
	_logmessage = function(self, text, data)
		local timestamp = inmation.gettime(inmation.now())
		table.insert( self.log.messages, {TimeStamp=timestamp, MessageText = text, data= data } )
	end
}
return libmonitor