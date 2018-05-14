-- esi-io
local O = require 'esi-objects'

local lib = {}
function lib:INFO()
    return {
        version = {
            major = 0,
            minor = 1,
            revision = 1
        },
        contacts = {
            {
                name = "Sebastian Gau",
                email = "sebastian.gau@basf.com"
            }
        },
        library = {
            -- Filename is always "lib-" .. modulename and the modulename must be used for the ScriptLibrary.LuaModuleName property.
            modulename = "esi-io",
            dependencies = {
                {
                    modulename = 'esi-objects',
                    version = {
                        major = 0,
                        minor = 1,
                        revision = 1
                    }
                }
            }
        },
    }
end

function lib.getpath(path)
    --detect relative path
    if not path then
        return inmation.getself():parent():path()
    end
    if tostring(path) and path == "" then
        return inmation.getself():parent():path()
    end
    if tostring(path) and not path:find("System/Core") then
        local p = inmation.getself():parent():path()
        if tostring(path) and #path>0 then
            return p .. "/" .. path
        end
    end
    return path
end

function lib:ENSUREFOLDER(path, foldername, desc, additional)
    local properties =
    {
        [".ObjectName"] = foldername,
        [".ObjectDescription"] = desc,
    }
    if additional then
        for k, v in pairs(additional) do
            properties[k] = v
        end
    end
    path = lib.getpath(path)

    local o, changed, new
    local ok, err = pcall(function()
        o, changed, new = O:UPSERTOBJECT({path = path, 
        class = "MODEL_CLASS_GENFOLDER", 
        properties = properties})
    end)
    if not ok then
        error("Error upserting object: " .. err, 2)
    end
    return o, changed, new
end

function lib:ENSUREHOLDER(path, holdername, desc, unit, additional)
    local properties =
    {
        [".ObjectName"] = holdername,
        [".ObjectDescription"] = desc,
        [".OpcEngUnit"] = unit,
        [".ArchiveOptions.ArchiveSelector"] = inmation.model.codes.ArchiveTarget.ARC_PRODUCTION,
        [".ArchiveOptions.StorageStrategy"] = 1,
    }

    if additional then
        for k, v in pairs(additional) do
            properties[k] = v
        end
    end

    

    path = lib.getpath(path)

    local o, changed, new
    local ok, err = pcall(function()
        o, changed, new = O:UPSERTOBJECT({ path = path, 
        class = "MODEL_CLASS_HOLDERITEM", 
        properties = properties})
    end)
    if not ok then
        error("Error upserting object: " .. err, 2)
    end
    return o, changed, new, properties
end

function lib:ENSUREACTIONITEM(path, name, desc, code, dedicated, additional)
    local properties =
    {
        [".ObjectName"] = name,
        [".ObjectDescription"] = desc,
        [".AdvancedLuaScript"] = code,
        [".DedicatedThreadExecution"] = dedicated,
        [".ArchiveOptions.ArchiveSelector"] = inmation.model.codes.ArchiveTarget.ARC_TEST,
        [".ArchiveOptions.StorageStrategy"] = 1,
    }
    path = lib.getpath(path)

    if additional then
        for k, v in pairs(additional) do
            properties[k] = v
        end
    end

    local o, changed, new
    local ok, err = pcall(function()
        o, changed, new = O:UPSERTOBJECT({path=path, 
        class = "MODEL_CLASS_ACTIONITEM", 
        properties = properties})
    end)
    if not ok then
        error("Error upserting object: " .. err, 2)
    end
    return o, changed, new
end

return lib