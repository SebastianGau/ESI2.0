-- esi-tables
local esitbllib =
{
    toolib = require'inmation.Toolbox',
    strlib = require'inmation.String',
    catlib = require'inmation.ESI.Catalog',

    --[[@md 
### INFO

This is a mandatory function for every ESI library.

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

    -- a Table class, which is representing an inmation TableHolder (or any inmation table data)
    Table =
    {
        -- a Schema class, which allows to define a table schema to test data integrity
        Schema =
        {
            -- a Field class, which allows to define schema restrictions per field
            Field =
            {
                name = nil,
                expected_type = nil,
                discrete = false,
                case_sensitive = false,
                value_set = nil,
                unique_throughout_table = false,
                nonempty = false,
                replacement = nil,
                timespan = false,
                object = nil,

                _new = function(class, o)
                    -- construct the object
                    o = o or {}
                    class.__index = class
                    local this = setmetatable(o, class)
                    -- return the instance
                    return this
                end,

                -- @md
                SETREQUIRED = function(this)
                    this.required = true
                    return this
                end,

                -- @md
                SETEXPECTEDTYPE = function(this, typename)
                    local F = string.format
                    local L = esitbllib
                    local NOF = L.strlib.noneof
                    local s = typename:lower()
                    if NOF(s, "string", "number", "boolean") then
                        NOTAIL(ESIERR(F("Attempt to set expected type to non-supported type '%s'", tostring(typename))))
                    end
                    this.expected_type = s
                    return this
                end,

                -- @md
                SETDISCRETE = function(this)
                    this.discrete = true
                    return this
                end,

                -- @md
                SETRANGE = function(this, low, high)
                    if low then
                        this.low = tonumber(low)
                    end
                    if high then
                        this.high = tonumber(high)
                    end
                    if this.low and this.high and (this.low > this.high) then local x = this.low; this.low = this.high; this.high = x end
                    return this
                end,

                -- @md
                SETVALUESET = function(this, tbl)
                    if not "table" == type(tbl) then this.value_set = { tbl } else this.value_set = tbl end
                    return this
                end,

                -- @md
                SETUNIQUE = function(this)
                    this.unique_throughout_table = true
                    return this
                end,

                -- @md
                SETNONEMPTY = function(this, replacement)
                    this.nonempty = true
                    this.replacement = replacement
                    return this
                end,

                -- @md
                ASTIMESPAN = function(this)
                    this.timespan = true
                    return this
                end,

                _asobject = function(this, which)
                    this.object = which
                    return this
                end,

                -- @md
                ASDATASOURCEOBJECT = function(this)
                    return this:_asobject("MODEL_CLASS_DATASOURCE")
                end,


            },
            -- all ESI key/value maps of class instances always have the same name as the class, but lower key and plural
            fields = nil,
            table = nil,

            -- tests the uniqueness of field data throughout the table column
            _testuniquecolumns = function(this, success, details)
                local L = esitbllib
                local F = string.format
                if nil == success then
                    success = true
                    details = ""
                end
                if not this.table or not this.table.data then
                    success = false
                    details = "Underlying table does not exist\n"
                end
                if not success then return success, details end
                for k, v in pairs(this.fields) do
                    if v.unique_throughout_table then
                        local x = {}
                        for n = 1, #this.table.data do
                            local f = this.table.data[n][k]
                            if L.strlib.empty(f) then
                                success = false
                                details = F("%sField '%s' is empty, which collides with required uniqueness. The first empty field was found in row %d\n", details, k, n)
                                break
                            elseif x[f] then
                                success = false
                                details = F("%sField '%s' not unique. row %d and %d hold the same field value '%s'\n", details, k, x[f], n, f)
                                break
                            else
                                x[f] = n
                            end
                        end
                    end
                end
                TRACE(F("Schema uniqueness tested (success=%s, details=%s)", tostring(success), tostring(details)))
                return success, details
            end,

            _testcolumnfill = function(this, success, details)
                local L = esitbllib
                local F = string.format
                local columns = 0
                local fields = 0
                local replaced = 0
                if nil == success then
                    success = true
                    details = ""
                end
                if not this.table or not this.table.data then
                    success = false
                    details = "Underlying table does not exist\n"
                end
                if not success then return success, details end
                for k, v in pairs(this.fields) do
                    if v.nonempty then
                        columns = columns + 1
                        for n = 1, #this.table.data do
                            if nil == this.table.data[n][k] then
                                success = false
                                details = F("Table does not contain a field '%s'", tostring(k))
                                break
                            end
                            fields = fields + 1
                            local f = this.table.data[n][k]
                            if L.strlib.empty(f) then
                                if not L.strlib.empty(v.replacement) then
                                    this.table.data[n][k] = v.replacement
                                    replaced = replaced + 1
                                else
                                    success = false
                                    details = F("col '%s', row %d is empty", k, n)
                                    break
                                end
                            end
                        end
                    end
                    if not success then
                        break
                    end
                end
                TRACE(F("Data fill tested (success=%s, details=%s, cols checked=%d, fields checked=%d, replaced fields=%d)", tostring(success), tostring(details), columns, fields , replaced))
                return success, details
            end,

            _testcolumntypes = function(this, success, details)
                local L = esitbllib
                local F = string.format
                local columns = 0
                local fields = 0
                if nil == success then
                    success = true
                    details = ""
                end
                if not this.table or not this.table.data then
                    success = false
                    details = "Underlying table does not exist\n"
                end
                if not success then return success, details end
                for k, v in pairs(this.fields) do
                    -- timespan testing
                    if v.timespan then
                        columns = columns + 1
                        for n = 1, #this.table.data do
                            fields = fields + 1
                            local f = this.table.data[n][k]
                            local ts = tonumber(L.toolib.reltime(f))
                            if not ts or 0 == ts then
                                success = false
                                details = F("col '%s', row %d, '%s' is not a valid timespan", k, n, f)
                                break
                            end
                        end
                    elseif not L.strlib.empty(v.object) then
                        columns = columns + 1
                        for n = 1, #this.table.data do
                            fields = fields + 1
                            local f = this.table.data[n][k]
                            local obj = inmation.getobject(f)
                            if not OBJECT(obj) then
                                obj = L.catlib:FINDONE("ObjectName", f)    
                            end
                            if not OBJECT(obj) then
                                success = false
                                details = F("col '%s', row %d, '%s' is not a valid inmation object", k, n, f)
                                break
                            end
                        end
                    end
                    if not success then
                        break
                    end
                end
                TRACE(F("Data types tested (success=%s, details=%s, typed cols=%d, tested fields=%d)", tostring(success), tostring(details), columns, fields))
                return success, details
            end,

            -- standard ESI constructor
            _new = function(class, o)
                -- construct the object
                o = o or {}
                class.__index = class
                local this = setmetatable(o, class)
                -- return the instance
                return this
            end,

            ADDFIELD = function(this, name)
                this.fields = this.fields or {}
                if not this.fields[name] then this.fields[name] = this.Field:_new{name=name} end
                return this.fields[name]
            end,

            INTEGRITYCHECK = function(this)
                local success = nil
                local details = nil
                -- test uniqueness
                success, details = this:_testuniquecolumns(success, details)
                if not success then return success, details end
                -- test non-emptyness (also does replacements in the data)
                success, details = this:_testcolumnfill(success, details)
                if not success then return success, details end
                -- test types
                success, details = this:_testcolumntypes(success, details)
                if not success then return success, details end

                return success, details
            end,
        },
        schema = nil,

        object = nil,
        loaded = false,
        data = nil,
        empty = true,
        rows = 0,
        columns = 0,
        updates = 0,
        header = nil,

        -- makes the Table (Lua) object reusable
        _reset = function(this)
            this.object = nil
            this.loaded = false
            this.data = nil
            this.empty = true
            this.rows = 0
            this.columns = 0
            this.header = nil
        end,

        -- loads the table data from the given inmation object
        _load = function(this)
            -- aliases
             local F = string.format
            -- create source address and get the data
            local inp = F("%s.%s", this.input, "TableData")
            this.loaded, this.data = pcall(function() return inmation.getvalue(inp) end)
            if not this.loaded then
                local err = tostring(this.data)
                this.data = nil
                NOTAIL(ESIERR(F("Table data could not be loaded from '%s' (error=%s)", tostring(inp), err)))
                return
            end
            -- analyze the table data
            this.rows = #this.data
            this.empty = 0 == this.rows
            this.columns = 0
            if this.empty then
                TRACE(F("Table data successfully loaded from '%s', but table is empty", inp))
                return
            end
            for _, row in ipairs(this.data) do
                for field,_ in pairs(row) do
                    this.columns = this.columns + 1
                    this.header = this.header or {}
                    table.insert(this.header, field)
                end
                if this.header then
                    TRACE(F("Table data successfully loaded from '%s', columns=%d, rows=%s", inp, this.columns, this.rows))
                    return
                end
            end
        end,

        -- reloads the current data from the inmation object
        _reload = function(this)
            this:_reset()
            this:_load()
            if this.loaded then
                this.updates = this.updates + 1
            end
        end,

        -- creating a new (Lua) Table object, reflecting the table data of an inmation TableHolder object
        _new = function(class, o)
            -- aliases
            local F = string.format
            local L = esitbllib
            -- construct the object
            o = o or {}
            class.__index = class
            local this = setmetatable(o, class)
            -- basic check and load table data
            if L.strlib.empty(this.input) then NOTAIL(ESIERR("Table must be loaded from valid input object or reference", F("Given was '%s' of type '%s'", tostring(o.input), type(o.input)))) end
            this:_load(this.input)
            -- return this instance, which is supposed to be mapped in the libraries key/instance list 'tables'
            return this
        end,

        -- @md
        LOADED = function(this) return this.loaded end,

        -- @md
        ROWS = function(this) return this.rows end,

        -- @md
        COLUMNS = function(this) return this.columns end,

        -- @md
        FOREACHROW = function(this, scope, fnc)
            local F = string.format
            local allidle = true
            for _, v in ipairs(this.data) do
                local continue, idle = fnc(scope, v)
                if not continue then 
                    TRACE("Break was set in FOREACHROW()")
                    break 
                end
                 allidle = allidle and idle
            end
            if allidle then
                TRACE("All objects idle in FOREACHROW()")
            end
            return allidle
        end,

        -- @md
        LOOKUP = function(this, column, other_column, other_colum_value)
            for _, row in ipairs(this.data) do
                if not (row[column] and row[other_column]) then return nil end
                if tostring(row[other_column]):lower() == tostring(other_colum_value):lower() then
                    return row[column]
                end
            end
            return nil
        end,

        -- @md
        SCHEMA = function(this)
            this.schema = this.schema or this.Schema:_new{ table=this }
            return this.schema
        end,

    },
    tables = nil,

    --[[@md


    @md]]
    TABLE = function(self, object_or_reference)
        -- aliases
        local F = string.format
        -- startup
        TRACE("ESI.Tables:TABLE() called")
        self.tables = self.tables or {}
        -- if an object is given, try to get the path
        if "table" == type(object_or_reference) then
            -- $TODO: SAFEPATH needs to be implemented as an ESI global
            --object_or_reference = SAFEPATH(object_or_reference)
            NOOP()
        end
        -- check integrity of the string parameter
        if "string" ~= type(object_or_reference) then
            return NOTAIL(ESIERR(F("Table object must be given as string (object path or reference), not as type '%s'.", type(object_or_reference))))
        elseif self.strlib.empty(object_or_reference) then
            return NOTAIL(ESIERR("Object path or reference cannot be empty.", "Please read the ESI documentation to learn how to use the TABLE() call."))
        end
        local key = object_or_reference
        self.tables[key] = self.tables[key] or self.Table:_new{ input=key }
        if self.tables[key]:LOADED() then
            TRACE(F("Table '%s' loaded successfully", key))
            return self.tables[key]
        else
            return NOTAIL(ESIERR(F("Table object '%s' could not be reflected in script code.", tostring(object_or_reference))))
        end
    end,
}
return esitbllib


