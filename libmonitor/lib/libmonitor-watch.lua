-- libmonitor-watch
libmonitor =
{
	INFO = function()
        return {
			version = {
            	major = 0,
            	minor = 0,
				revision = 5
          	},
          	contacts = {
            	{
              		name = "Florian Seidl",
              		email = "florian.seidl@cts-gmbh.de"
            	},
          	},
          	library = {
            	modulename = "libmonitor-watch",
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
						modulename= "inmation.ESI.Objects",
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
	JSON = require'dkjson',
	ESIOBJLIB = require'inmation.ESI.Objects',
	--
	log = {},
	debugging = false,
	--@md
	CHECKLIBVERSION = function(self)
		local rt = inmation.now()
		local O = self.ESIOBJLIB
		local ok, content = pcall(self._checklibversion, self)
		O:SETVARIABLE("PerformanceCounter/runtime", inmation.now() -rt)
		if ok == false then
			O:SETVARIABLE("Debug/error", content)
		end
		return ok
	end,
	--
	_checklibversion = function(self)
		local J = self.JSON
		local O = self.ESIOBJLIB
		local data = {}
		local parentpath = self.rootpath or inmation.getparentpath(inmation.getselfpath())
		local obj = inmation.getself()
        local objectname = obj.ObjectName .. " Configuration Table"
        local exists, tableholder = O:EXISTS{ ["parentpath"] = parentpath, ["objectname"] = objectname }
        if exists == false then
			tableholder = O:UPSERTOBJECT{path = parentpath, class = "MODEL_CLASS_TABLEHOLDER", properties = {[".ObjectName"] = objectname,
			}}
            tableholder.TableData = '{  "data": {    "host": [      ],    "name": [      ],    "user": [      ],    "password": [      ],    "port": [      ],    "ctx": [      ]  }}'
            tableholder:commit()
        end
		local cores = tableholder.TableData
		for _,core in pairs(cores) do
			local libs = self:_getlibsfromcore(core)
			table.insert( data, {["libs"] = libs, ["host"] = core.host,["name"] = core.name})
		end
		O:SETVARIABLE("Result", data)
		return true
	end,
	-- get libs from core using the information to make the web all and check the parameters
	_getlibsfromcore = function(self, core)
		local call = "v2b?lib=libmonitor&func=getalllibs"
		if type(core.ctx) == "string" then
			if core.ctx ~= "" then
				local ctx = core.ctx
				ctx = ctx:gsub("/","%%2F")
				ctx = ctx:gsub(" ","%%20")
				call = call .. "&ctx=" .. ctx
			end
		end
		local port = "8002"
		
		if type(core.port) == "string" then
			if core.port ~= "" then
				port = core.port
			end
		end
		system = {
			host =  core.host,
			port = port,
			basecall = "api/v2/execfunction",
			method = "GET",
			user = core.user,
			password = core.password
		}
		local libs = self:_webcall(call, system)
		if type(libs) == "table" then
			for k, lib in ipairs(libs) do
				if type(lib.INFO) == "table" then
					local info, version = self:_infoconversion(lib.INFO)
					libs[k].INFO = {info} 
					libs[k].VERSION = version
				end
			end
		end
		return libs
	end,
	-- converts info to a reportable info version
	_infoconversion = function(self, libinfo)
		local info = libinfo[1]
		if type(info) == "table" then
			if type(info.library) =="table" and type(info.contacts) =="table" and type(info.version) =="table" then
				local O = self.ESIOBJLIB
				local version = nil
				local ok, content = pcall(function()
					version = info.version.major ..  "." .. info.version.minor ..  "." .. info.version.revision
					local newinfo = {
						version = {info.version},
						contacts = info.contacts,
						library = {{
							modulename = info.library.modulename,
							dependencies = {}
						}}
					}
					if type(info.library.dependencies) == "table" then
						for _,dep in ipairs(info.library.dependencies) do
							local newdep = {modulename = dep.modulename, ["dependencies-version"] = {dep.version}}
							table.insert( newinfo.library[1].dependencies, newdep )
						end
					end
					return newinfo

				end)
				if ok then
					return content, version
				end
				O:SETVARIABLE("debug/_infoconversion/info", info)
				O:SETVARIABLE("debug/_infoconversion/pcall content", content)
			end
		end
		return nil, nil
	end,
	--Read over http-Interface
    _webcall = function(self, call, system)
        local tcall = inmation.now()
        local O = self.ESIOBJLIB
        local J = self.JSON
		local ltn12 = require("ltn12")
        local localsocket = require "socket.http"
        local host = system.host
        local port = system.port
        local basecall = system.basecall
        local method = system.method or "GET"
		local payload = system.payload or [[ {} ]]
		local user = system.user
		local password = system.password
		if type(payload) == "table" then
			payload = J.encode(payload)
		end
        local ResultTable = {}
		local url = "http://" .. host..":" .. port .. "/".. system.basecall .. "/" .. call
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
		if self.debugging then
			O:SETVARIABLE("debug/call/" .. basecall .. "/url",url)
			O:SETVARIABLE("debug/call/" .. basecall .. "/r1",r1)
			O:SETVARIABLE("debug/call/" .. basecall .. "/result1",result1)
			O:SETVARIABLE("debug/call/" .. basecall .. "/result2",result2)
			O:SETVARIABLE("debug/call/" .. basecall .. "/ResultTable",ResultTable)
			O:SETVARIABLE("debug/call/" .. basecall .. "/ResultTable type",type(ResultTable))
			O:SETVARIABLE("debug/call/" .. basecall .. "/status",status)
			O:SETVARIABLE("debug/call/" .. basecall .. "/content",content)
		end
		if type(ResultTable) == "table" then
			ResultTable = J.decode( table.concat(ResultTable))
		end
		if type(ResultTable) == "string" then
            ResultTable = J.decode(ResultTable) or ResultTable
        end
        table.insert( self.log, {["time"] = inmation.now() - tcall,["url"] = url})
        return ResultTable
	end,
	-- @md
	DEBUGGING = function(self, value)
		self.debugging = value
	end
}
return libmonitor