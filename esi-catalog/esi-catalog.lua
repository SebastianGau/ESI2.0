-- esi-catalog

-- TODOS:
-- use esierrors
local cat = 
{
    db = inmation.getsystemdb(),
    customstr = {'@', 'CustomPropertyName.'}
}

------------------ PROPERTIES --------------------
--------------------------------------------------
--- Filters objects depending on their properties' values
--- The properties, operators and values can be provided as tables, in which case they are mapped one to one. 
--- When the properties table is empty, an empty table is returned.
--- When there are less operators than properties, the missing positions are filled with the default operator '='
--- When there are less values than properties, the missing positions are filled with the last provided value
-- @param properties It can be a string representing the property's name or a table with such strings
-- A custom property can be specified with its defined name or, in case this collides with an already existing
-- property, it can be prepended with "CustomPropertyName." or "@"
-- @param values It can be nil or a single value or a table with values
-- @param operators It can be nil or a string representing an SQL operator (e.g. IS, LIKE etc.) or a table with such strings
-- @return A table with the filtered objects or an error message
--------------------------------------------------
function cat:filterByPropValue(properties, values, operators)
    if properties == nil or (type(properties) ~= 'table' and type(properties) ~= 'string') then
        error("Invalid properties argument! type : " .. type(properties), 3)
    end

    if type(properties) == 'string' then
        properties = {properties}
    end

    if type(operators) ~= 'table' then
        if operators == nil then
            operators = {}
        else
            if type(operators) ~= 'string' then
                error("operators argument has to be either a table or string! type " .. type(operators), 3)
            end
            operators = {operators}
        end
    end

    --assume equality operator if they are missing
    for i = #operators + 1, #properties do
        operators[i] = '='
    end

    if type(values) ~= 'table' then
        if type(values) ~= 'string' then
            error("values argument has to be either a table or string! type " .. type(values), 3)
        end
        values = {values}
    end
    local lastval = values[#values]
    for i = #values + 1, #properties do
        values[i] = lastval
    end

    local objects = {}
    local query = "SELECT p1.objid as oid FROM properties p1"	

    -- build the first part of the query
    local first_part_simple = " INNER JOIN properties p%s ON p%s.objid = p1.objid"
    local first_part_custom = " INNER JOIN properties p%s ON p%s.objid = p%s.objid AND p%s.position = p%s.position"

    --detect custom properties
    if inmation.model.properties[properties[1]] == nil then
        query = query .. string.format(first_part_custom, 11, 11, 1, 11, 1)
    end

    for i=2, #properties do
        if inmation.model.properties[properties[i]] ~= nil then -- simple property
            query = query .. string.format(first_part_simple, i, i)
        else -- custom property
            query = query .. string.format(first_part_simple, i, i)
            query = query .. string.format(first_part_custom, i..i, i..i, i, i..i, i)
        end
    end

    -- build second part of the query
    local where = " WHERE p1.code = %s AND p1.value %s %s"
    local second_part_simple = " AND p%s.code = %s AND p%s.value %s %s"

    local codekey = inmation.model.properties.CustomPropertyName
    local codeval = inmation.model.properties.CustomPropertyValue

    local code = inmation.model.properties[properties[1]]
    if type(values[1]) == 'string' then
        values[1] = "'" .. values[1] .. "'"
    elseif type(values[1]) == 'table' and string.find(operators[1], 'BETWEEN') ~= nil then -- BETWEEN or NOT BETWEEN
        values[1] = values[1][1] .. ' AND ' .. values[1][2]
    end	
    if code ~= nil then
        query = query .. string.format(where, code, operators[1], values[1])
    else
        local key = string.gsub(properties[1], '@', '')
        key = string.gsub(key, self.customstr[2], '')
        query = query .. string.format(where, codekey, "=", "'" .. key .. "'")
        query = query .. string.format(second_part_simple, 11, codeval, 11, operators[1], values[1])
    end

    local second_part_custom = " AND p%s.code = %s AND p%s.value = %s AND p%s.code = %s AND p%s.value %s %s"

    for i=2, #properties do
        code = inmation.model.properties[properties[i]]		
        if type(values[i]) == 'string' then
            values[i] = "'" .. values[i] .. "'"
        elseif type(values[i]) == 'table' and string.find(operators[i], 'BETWEEN') ~= nil then
            values[i] = values[i][1] .. ' AND ' .. values[i][2]
        end	
        if code ~= nil then
            query = query .. string.format(second_part_simple, i, code, i, operators[i], values[i])
        else
            local key = string.gsub(properties[i], self.customstr[1], '')
            key = string.gsub(key, self.customstr[2], '')
            query = query .. string.format(second_part_custom, i, codekey, i, "'" .. key .. "'", i..i, codeval, i..i, operators[i], values[i])
        end
    end

    local cur, err = self.db:query(query)
    if cur == nil then
        error("Error executing query: " .. tostring(err), 3)
    else
        local row = cur:fetch ({}, "a")
        while row do
            table.insert(objects, inmation.getobject(row.oid))
            row = cur:fetch (row, "a") -- get the next row
        end
    end

    return objects
end

---------------- LIVE PROPERTIES -----------------

--------------------------------------------------
--- Filters objects depending on their dynamic or volatile properties' values
-- @param value A value representing the argument of the SQl operator
-- @param operator It can be nil or a string representing an SQL operator (e.g. IS, LIKE etc.)
-- @return A table with the filtered objects or an error message
--------------------------------------------------
function cat:filterByLivePropValue(property, value, operator)
    if property == nil or type(property) ~= 'string' then
        return "Invalid argument! The property must be suplied as a string."
    end

    if operator == nil then
        operator = '='
    end

    local objects = {}
    local query = "SELECT objid FROM live_properties WHERE code = %s AND value %s %s"	

    local code = inmation.model.properties[property]		
    if type(value) == 'string' then
        value = "'" .. value .. "'"
    end	

    query = string.format(query, code, operator, value)

    local cur, err = self.db:query(query)
    if cur == nil then
        return err
    else
        local row = cur:fetch ({}, "a")
        while row do
            table.insert(objects, inmation.getobject(row.objid))
            row = cur:fetch (row, "a") -- get the next row
        end
    end

    return objects, query
end




-- inmation.ESI.Catalog (simplifies catalog access)
-- timo.klingenmeier@inmation.com
local lib = 
{
    dbglib = require'debug',
    catlib = cat,
}

function lib:INFO()
    return {
        version = {
            major = 0,
            minor = 1,
            revision = 1
        },
        contacts = {
            {
                name = "Timo Klingenmeier",
                email = "timo.klingenmeier@inmation.com"
            },
            {
                name = "Sebastian Gau",
                email = "sebastian.gau@basf.com"
            },
        },
        library = {
            -- Filename is always "lib-" .. modulename and the modulename must be used for the ScriptLibrary.LuaModuleName property.
            modulename = "esi-catalog",
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
        },
    }
end

--just commented out temporarily
function lib:esicheck()
    -- local D = self.dbglib.traceback
    -- if not ESIERR then 
    -- 	error(D("function (second on stack) must be called in a valid ESI environment; call ESI:SCRIPT():START() first "))
    -- end
end

function lib:findbytable(props, settings, operators)
    self:esicheck()
    local olist = self.catlib:filterByPropValue(props, settings, operators)
    error(type(olist))
end

-- internal function, may only be called from within the library!
-- translates a string parameter set into a table parameter set	
function lib:findbystring(props, settings, operators)
    self:esicheck()
    local p = {}
    local s = {}
    local o = {}
    local olist
    if "table" == type(settings) then
        -- check whether the operators are less equal the settings to search for
        if "table" == type(operators) then
            if #operators > #settings then
                return NOTAIL(ESIERR("'operators' count may not be larger than 'settings' count"))
            end
        end
        for n=1, #settings do 
            p[n] = props
            s[n] = settings[n]
            o[n] = operators[n] or "="
        end
        olist = self.catlib:filterByPropValue(p, s, o)
    end
    -- classical string call
    if not props or props == "" then
        return error("'props' cannot be an empty string", 2)
    end
    p[1] = props
    s[1] = settings
    if operators then o[1] = operators end
    olist = self.catlib:filterByPropValue(p, s, o)
    return olist
end

-- flexible object finder based on the component catalog
function lib:FIND(props, settings, operators)
    if type(props)=="string" and type(settings)=="string" 
    and (type(operators)=="string" or type(operators)=="nil") then
        return self.catlib:filterByPropValue(props, settings, operators)
    end
    if type(props)=="table" and type(settings)=="table" 
    and (type(operators)=="table" or type(operators)=="nil") then
        if #props ~= #settings then
            error("Properties and values table need to have the same length!")
        end
        return self.catlib:filterByPropValue(props, settings, operators)
    end
end

function lib:FINDONE(props, settings, operators)
    local x
    local o, e = pcall(function()
        x = self:FIND(props, settings, operators)
    end)
    if not o then
        error("Could not find one object due to error: " .. tostring(e))
    end
    if #x == 1 then
        return x[1]
    end
    return nil
end

-- free-form query
-- function lib:QUERY(query)
--     self:esicheck()
--     local olist = self.catlib.db:query(query)
-- end

return lib

