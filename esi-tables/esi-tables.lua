-- esi-tables
local H = require 'esi-bucket'
local O = require 'esi-objects'
local JSON = require 'dkjson'
local SCHEMA = require 'esi-schema'
local XP = require 'esi-luaxp'

-- esi-tables
local tbl =
{
    config =
    {
        emptyidentifier = nil
    },
    state =
    {
        mode = "persistoncommand", --or "persistimmediately"
        holderobj = {},
        data = {},
        columns = {}, --columns[columnname] = true
        insync = false, --means that the holders table and the table inside this object are potentially out of sync
        schema = nil,
        columnssynchronized = false, --means that a non-empty table was read and the columns were extracted
        emptyinimage = false, --means that the table was empty on last reading from the holder
        wasnewcreated = false, --means that the table was new created at the time of initialization
    }
}

function tbl:INFO()
    return {
        version = {
            major = 0,
            minor = 1,
            revision = 2
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
            modulename = "esi-tables",
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
                    modulename = 'esi-bucket',
                    version = {
                        major = 0,
                        minor = 1,
                        revision = 1
                    }
                },
                {
                    modulename = 'esi-schema',
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

function tbl:_isempty()
    return #(self.state.data)==0
end

function tbl:_synctoimage()
    self.state.holderobj.TableData = self.state.data
    self.state.holderobj:commit()
    self.state.insync = true
end

--problem: sync columns from image with empty table
function tbl:_syncfromimage()
    self.state.data = self.state.holderobj.TableData 
--returns an empty table even if there were columns initialized
    self.state.columns = {}

    if not self.state.data then
        error("Unexpected error: .TableData property returned an empty lua table!")
    end
    if #(self.state.data)==0 then
        self.state.emptyinimage = true
        --self.state.data = {}
        self.state.columnssynchronized = false
    else
        self.state.emptyinimage = false
        for i=1, #(self.state.data) do
            for col, val in pairs(self.state.data[i]) do
                self.state.columns[col] = true
            end
        end
        self.state.columnssynchronized = true
    end
    self.state.insync = true
end

function tbl:_lazysyncfromimage()
    if not self.state.insync then
        self:_syncfromimage()
    end
end

function tbl:_lazysynctoimage()
    if not self.state.insync then
        self:_synctoimage()
    end
end

function tbl:_columnexists(colname)
    if self.state.columns[colname] then
        return true
    end
    return false
end

function tbl:_syncifnecessary()
    if self.state.mode == "persistimmediately" then
        self:_synctoimage()
    end
end


function tbl:_validateinputschema(sc)
    local s = SCHEMA

    --maps from integer to string or number
    local valset1 = s.Map(s.Integer, s.OneOf(s.String, s.Number))

    --a table with field "luatype" with values "string" "boolean" or "number"
    local valset2 = s.Record{
        luatype = s.OneOf("string","boolean","number")
    }

    local valset3 = s.Record{
        mathexpression = s.Boolean
    }

    local valset4 = s.Record{
        regex = s.String
    }

    local valset = s.OneOf(valset1, valset2, valset3, valset4)

    local colelement = s.Record {
        name = s.String,
        required = s.Boolean,
        unique = s.Boolean,
        nonempty = s.Boolean,
        valueset = valset
    }

    local completeSchema = s.Record {
        maxrows = s.PositiveNumber,
        columns = s.Map(s.Integer, colelement) --
    }

    local given = sc --self.state.schema

    local err = s.CheckSchema(given, completeSchema)

    if err then
        return nil, s.FormatOutput(err)
    end
    return true
end


function tbl:_setschema(schema)
    self.state.schema = schema
end

function tbl:SETSCHEMA(schema)
    local ok, err = self:_validateinputschema(schema)
    if not ok then
        error("Error validating input schema: " .. err, 2)
    end
    self:_setschema(schema)
end

--
function tbl:VALIDATESCHEMA()
    local data = self.state.data
    local fails = {}
    local schema = self.state.schema
    if not schema then error("No schema was set!", 2) end

    if schema.maxrows and self:ROWCOUNT() > schema.maxrows then 
        table.insert(fails, "Maximum number of rows exceeded! Count: " .. self:ROWCOUNT() .. ", maximum according to schema: " .. schema.maxrows)
    end

    for _, col in pairs(schema.columns) do
        --check required columns
        if self:COLUMNEXISTS(col.name)==false and col.required then
            table.insert(fails, "Mandatory column " .. col.name .. " is missing!")
            goto skipcolumn
        end
        --start to check the column
        local seen = {}
        for i=1, #(data) do
            local val = data[i][col.name]
            --check emptyness
            if tostring(val)==tostring(self.config.emptyidentifier) and col.nonempty then
                table.insert(fails, "empty value for " .. col.name .. " at index " .. i)
                -- local h = self.JSON.encode(self.H.DEEPCOPY(data))
                -- error("data: " .. h)
                goto skiptherest
            end
            --check uniqueness
            if seen[val] and col.unique then
                table.insert(fails, "double value for column " .. col.name .. " at index " .. i)
            else
                seen[val] = true
            end
            --check type
            if col.valueset then 
                if col.valueset.mathexpression then
                    local pr, message = XP.compile(tostring(val))
                    if (pr == nil) then
                        -- Parsing failed
                        table.insert(fails, "invalid type for column " .. col.name .. " at index " .. i
                            ..", parsing expression failed, reason: " .. message)
                    end
                elseif col.valueset.regex then
                    if not val:match(col.valueset.regex) then
                        table.insert(fails, "invalid value for column " .. col.name .. " at index " .. i
                            ..", expected match to pattern " .. col.valueset.regex .. " , got value: " .. tostring(val))
                    end
                elseif col.valueset.luatype then --valueset = {luatype="string"},
                    if tostring(col.valueset.luatype) == "number" then
                        if not tonumber(val) then
                            table.insert(fails, "invalid type for column " .. col.name .. " at index " .. i
                            ..", expected numbers, got " .. type(val) .. ", value: " .. tostring(val))
                        end
                    elseif type(val) ~= col.valueset.luatype then
                        table.insert(fails, "invalid type for column " .. col.name .. " at index " .. i
                            ..", expected " .. tostring(col.valueset.luatype) .. ", got " .. type(val) .. ", value: " .. tostring(val))
                    end
                else --valueset {"asd","sad", 1},
                    local rev = {}
                    for k, v in pairs(col.valueset) do rev[tostring(v)] = k end
                    if not rev[tostring(val)] then --whats with nil values?
                        table.insert(fails, "invalid value for column " .. col.name .. " at index " .. i
                            ..", expected values" .. JSON.encode(col.valueset) .. ", got " .. tostring(val))
                    end
                end
            end
            ::skiptherest::
        end
        ::skipcolumn::
    end
    if #fails==0 then
        return true
    else
        return false, table.concat(fails, ", \n")
    end
end


function tbl:NEW(args)
    
    if not args or type(args)~='table' then error("invalid arguments given: " .. tostring(args)) end
    if not args.path then error("missing path field in arguments table!") end
    local path, oname
    if not args.objectname then
        path, oname = inmation.splitpath(args.path)
    else
        path, oname = args.path, args.objectname
    end

    local o, changed, newcreated = O:UPSERTOBJECT{path = path, 
        class="MODEL_CLASS_TABLEHOLDER", 
        properties =
        {
            [".ObjectName"] = oname
        }}

    if not o then
        error("object reference is nil! Object creation failed!")
    end

    local instance = {}
    instance.state = H.DEEPCOPY(self.state)
    instance.config = H.DEEPCOPY(self.config)
    self.__index = self
    instance = setmetatable(instance, self)

    instance.state.holderobj = o
    if args.mode and args.mode~="persistoncommand" then
        instance.state.mode = "persistimmediately"
    end
    if newcreated then
        instance.state.wasnewcreated = true
    end
    local existedbefore = not newcreated

    instance:_syncfromimage()
    return instance, existedbefore
end



function tbl:SAVE()  
    self:_synctoimage()
end


function tbl:_addcolumn(colname)
    if not self.state.columns[colname] then
        self.state.columns[colname] = true
        if self.config.emptyidentifier == nil then return nil end
        for i=1, #(self.state.data) do 
            --this does not do anything if data is empty
            --the columns are then added as soon as rows are added
            self.state.data[i][colname] = self.config.emptyidentifier
            self.state.insync = false
        end
    else
        error("Cannot add column " .. colname .. " since it already exists!", 3)
    end
end

function tbl:_removecolumn(colname)
    if self.state.columns[colname] then
        self.state.columns[colname] = nil
        self.state.insync = false
        for i=1, #(self.state.data) do 
            --this does not do anything if data is empty
            --the columns are then added as soon as rows are added
            self.state.data[i][colname] = nil
            self.state.insync = false
        end
    else
        error("Cannot remove column " .. colname .. " since it does not exist!")
    end
end

--t:ADDCOLUMNS{"col1","col2", "col3"}
--results in table and internal data out of sync!
function tbl:ADDCOLUMNS(args)
    if not args or type(args)~='table' then error("invalid arguments given: " .. tostring(args)) end

    for _, colname in pairs(args) do
        if type(colname) == 'string' then
            self:_addcolumn(colname)
        else
            error("only string column names allowed!", 2)
        end
    end

    self:_syncifnecessary()

    --if empty, example:
    --data["Tags"] = {}
    --inmation.setvalue(o:path() .. '.TableData', self.json.encode({data = data}))
end


function tbl:ENSURECOLUMNS(args)
    if not args or type(args)~='table' then error("invalid arguments given: " .. tostring(args)) end

    for _, colname in pairs(args) do
        if type(colname) == 'string' then
            if not self:_columnexists(colname) then
                self:_addcolumn(colname)
            end
        else
            error("only string column names allowed!", 2)
        end
    end

    self:_syncifnecessary()

    --if empty, example:
    --data["Tags"] = {}
    --inmation.setvalue(o:path() .. '.TableData', self.json.encode({data = data}))
end



function tbl:REMOVECOLUMNS(args)
    if not args or type(args)~='table' then error("invalid arguments given: " .. tostring(args)) end  

    for _, colname in pairs(args) do
        if type(colname) == 'string' then
            self:_removecolumn(colname)
        else
            error("only string column names are allowed!", 2)
        end
    end
    self:_syncifnecessary()
end


--ADDROW{col1 = "asd", col2 = 3}
function tbl:ADDROW(args)
    if not args or type(args)~='table' then error("invalid argument type: " .. tostring(args), 2) end

    local row = {}
    for coltoadd, colvalue in pairs(args) do
        if not self:_columnexists(coltoadd) then
            error("Column does not exist : " .. coltoadd, 2)
        end
    end
    for coltoadd, colvalue in pairs(args) do
        row[coltoadd] = colvalue
        self.state.insync = false
    end
    --this is only necessary if self.config.empty is not nil so that "empty" table cells have a default value
    for existingcolumn, _ in pairs(self.state.columns) do
        if type(row[existingcolumn])=='nil' then
            row[existingcolumn] = self.config.emptyidentifier
        end
    end
    table.insert(self.state.data, row)
    self.state.insync = false

    self:_syncifnecessary()
end


function tbl:_match(where, row)
    if not where then return true end
    if type(row)~='table' then error("Invalid type for row: " .. type(row)) end
    if type(where)=='table' then
        for col, val in pairs(where) do
            if not row[col] then --problem
                return false
            else
                if tostring(row[col]) ~= tostring(where[col]) then
                    return false
                end
            end
        end
        return true
    elseif type(where) =='function' then
        local rowrep = H.DEEPCOPY(row)
        local match 
        local ok, err = pcall(function() match = where(rowrep) end)
        if not ok then
            local col = JSON.encode(rowrep)
            error("Match function caused an error at column " .. col .. ": " .. err, 3)
        end
        if match then
            return true
        end
    elseif type(where) == 'nil' then
        return true
    else
        error("Invalid type for WHERE-field!", 3)
    end
    return false
end

function tbl:_valuetype(var)
    if type(var)=='string' or
    type(var)=='number' or
    type(var)=='boolean' then
        return true
    end
    return false
end

function tbl:_update(set, row)
    if type(row)~='table' then error("Invalid type for row: " .. type(row)) end
    if not set then error("no SET given!") end
    if type(set)=='table' then
        for col, val in pairs(set) do
            if self:_columnexists(col) then
                if self:_valuetype(row[col]) then
                    row[col] = set[col]
                    -- error("data: "  .. self.json.encode(self.state.data)
                    --.. " row[col]: " .. row[col] .. " set[col]: " .. set[col])
                    self.state.insync = false
                else
                    error("invalid type: " .. type(set[col]))
                end
            else
                error("Cannot set nonexistent column, use :ADDCOLUMN before! columnname : " .. tostring(col))
            end
        end
        return true
    elseif type(set)=='function' then
        local rowrep = H.DEEPCOPY(row)
        local ok, err = pcall(function()  set(rowrep) end) --error(self.json.encode(rowrep))
        if not ok then
            local col = JSON.encode(rowrep)
            error("Update function caused an error at column " .. col .. ": " .. err, 3)
        end
        for colname, _ in pairs(rowrep) do
            if not self:_columnexists(colname) then
                error("Trying to access nonexisting column in update function: " .. colname, 3)
            end
        end
        for col, val in pairs(rowrep) do
            row[col] = val
        end
        self.state.insync = false
        return true
    else
        error("Invalid type for SET argument: " .. type(set), 3)
    end
    return false
end

--  t:UPDATE
-- { 
--     WHERE = {col1 = "asd", col2 = "3"}, --a nonexistent column here will result in an error
--     SET = {col2 = 4, col3 = "asdasd"}
-- }
--  t:UPDATE
-- { 
--     WHERE = function(row) return row.col1 == "asd" and row.col2 == "3" end, --optional
--     SET = function(row) row.col2 = 4 row.col3 = "asdasd" end
-- }
function tbl:UPDATE(args)
    if not args or type(args)~='table' then error("invalid arguments given: " .. tostring(args), 2) end
    if not args.SET or (type(args.SET)~='table' and type(args.SET)~='function') then
        error("Invalid SET argument: " .. tostring(args.SET))
    end
    if args.WHERE and type(args.WHERE)~='table' and type(args.WHERE)~='function' then
        error("Invalid WHERE argument: " .. tostring(args.WHERE))
    end

    local updated = 0
    for linenum, row in pairs(self.state.data) do
        if self:_match(args.WHERE, row) then
            if self:_update(args.SET, row) then 
                updated = updated + 1 
            end
        end
    end

    self:_syncifnecessary()
    return updated
end

function tbl:SELECT(args)
    if not args or type(args)~='table' then error("invalid arguments given: " .. tostring(args), 2) end
    if not args.WHERE or (type(args.WHERE)~='table' and type(args.WHERE)~='function') then
        error("Invalid WHERE argument!", 2)
    end

    local ret = {}
    for linenum, row in pairs(self.state.data) do
        if self:_match(args.WHERE, row) then
            table.insert(ret, row)
        end
    end
    return ret --attention: perhaps return a deep clone here
end

function tbl:GETCOLUMN(args)
    if not args or type(args)~='table' then error("invalid arguments given: " .. tostring(args), 2) end
    if not args.NAME or (type(args.NAME)~='string') then
        error("Invalid NAME argument (column name): " .. type(args.Name), 2)
    end

    if not self:COLUMNEXISTS(args.NAME) then
        error("The column does not exist: " .. args.NAME, 2)
    end

    local ret = {}
    local data
    local ok, err = pcall(function()
        data = self:SELECT{WHERE = args.WHERE}
    end)
    if not ok then
        error("Error executing select: " .. err, 2)
    end
    for k, row in pairs(data) do
        table.insert(ret, row[args.Name])
    end
    return ret
end

function tbl:COLUMNS()
    local ret = {}
    for col, _ in pairs(self.state.columns) do
        table.insert(ret, col)
    end
    return ret
end

function tbl:COLUMNEXISTS(colname)
    if not colname or type(colname)~='string' then
        error("Invalid argument for columnname! " .. tostring(colname))
    end
    return self:_columnexists(colname)
end

function tbl:COLUMNCOUNT()
    return #(self:COLUMNS())
end

function tbl:ROWCOUNT()
    return #(self.state.data)
end

function tbl:CLEAR()
    self.state.data = {}
    self.state.columns = {}
    self.state.wasnewcreated = true
    self.state.insync = false
    self:_syncifnecessary()
end

function tbl:ENSURETEMPLATE(args)
    args.parentpath = args.parentpath or inmation.getparentpath(inmation.getselfpath())
    local exists, tableholder = self:EXISTS{ ["parentpath"] = args.parentpath, ["objectname"] = args.objectname }
    if exists == false then
        local tabledata = args.default
        tableholder = self:UPSERTOBJECT{path = args.parentpath, class = "MODEL_CLASS_TABLEHOLDER", properties = {[".ObjectName"] = args.objectname,
                --[".TableData"] = tabledata -- Todo after BugFix #000775
            }}
        tableholder.TableData = tabledata
        tableholder:commit()
    end
    --self:SETCONFIGURATIONTABLE(args.tablename, args.aliastree, tableholder.TableData)
    return self:SETCONFIGURATIONTABLE{table=args.table, aliastree=args.aliastree, TableData=tableholder.TableData}
end

function tbl:SETCONFIGURATIONTABLE(args)
    local S = self.strlib
    local data = args.table or {}
    for	_,tdrow in pairs(args.TableData) do
        local dataalias = data
        for _,alias in ipairs(args.aliastree) do
            if tdrow[alias] then
                dataalias[tdrow[alias]] = dataalias[tdrow[alias]] or {}
                dataalias = dataalias[tdrow[alias]]
            end
        end
        if dataalias then
            for kv,i in pairs(tdrow) do
                if self:VALUEINTABLE{table=args.aliastree, value=kv,where={v=true}} == false then
                    if kv:sub(1,1) .. kv:sub(-1,-1) == "[]" then
                        local kva = kv:sub(2,#kv -1)
                        dataalias[kva] = dataalias[kva] or {}
                        table.insert(dataalias[kva],i)
                    else
                        local bool1, bool2 = S.string2bool(i) --Todo change Lib
                        -- check if boolean or numerian value. if not, write down as string
                        if bool1 and bool2 then
                            dataalias[kv] = true
                        elseif not bool1 and bool2 then
                            dataalias[kv] = false
                        elseif tonumber(i) ~= nil then
                            dataalias[kv] = tonumber(i)
                        else
                            dataalias[kv] = i
                        end
                    end
                end
            end
        end
    end
    return data
end

return tbl


