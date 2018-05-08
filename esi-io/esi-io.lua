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

function lib:ENSUREFOLDER(path, foldername, desc, custom)
    local properties =
    {
        [".ObjectName"] = foldername,
        [".ObjectDescription"] = desc,
        Custom = custom
    }

    if not path or path == "" or path == "cwd" then
        path = inmation.getself():parent():path()
    end

    local o, changed, new
    local ok, err = pcall(function()
        o, changed, new = O:UPSERTOBJECT({path=path, 
        class = "MODEL_CLASS_GENFOLDER", 
        properties = properties})
    end)
    if not ok then
        error("Error upserting object: " .. err, 2)
    end
    return o, changed, new
end

function lib:ENSUREHOLDER(path, holdername, desc, custom)
    local properties =
    {
        [".ObjectName"] = holdername,
        [".ObjectDescription"] = desc,
        [".ArchiveOptions.ArchiveSelector"] = inmation.model.codes.ArchiveTarget.ARC_PRODUCTION,
        Custom = custom
    }

    if not path or path == "" or path == "cwd" then
        path = inmation.getself():parent():path()
    end

    local o, changed, new
    local ok, err = pcall(function()
        o, changed, new = O:UPSERTOBJECT({path=path, 
        class = "MODEL_CLASS_HOLDERITEM", 
        properties = properties})
    end)
    if not ok then
        error("Error upserting object: " .. err, 2)
    end
    return o, changed, new
end

function lib:ENSUREACTIONITEM(path, name, desc, code, custom)
    local properties =
    {
        [".ObjectName"] = name,
        [".ObjectDescription"] = desc,
        [".ScriptLibrary.AdvancedLuaScript"] = code,
        Custom = custom
    }

    if not path or path == "" or path == "cwd" then
        path = inmation.getself():parent():path()
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
