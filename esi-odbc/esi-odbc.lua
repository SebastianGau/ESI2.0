-- esi-odbc
local BUCKET = require 'esi-bucket'
local JSON = require 'dkjson'

-- Scope: The collection of statistical information about ODBC calls in this library
local _ODBCStatistics = {}
_ODBCStatistics.data = nil --a field for accumulating  statistical information about an odbc connection

function     _ODBCStatistics:_prec(num, prec)
    prec = prec or 2
    return tonumber(string.format(string.format("%%.%df",prec),num))
end

function _ODBCStatistics:_new(o)
    --without the deepcopy(self) here, all table field of the object point to the same table
    o = {}
    self.__index = self
    setmetatable(o, self)

    o.data = 
    {
        INITTIME = inmation.currenttime(),
        INITTIMELOCAL = inmation.gettime(inmation.currenttime(true)):gsub("Z",""),
        CALLS = 0,
        PERFORMANCE =
        {
            READ =
            {
                OVERALLMB = 0,
                OVERALLRECORDS = 0,
                MIN = 0,
                MAX = 0,
                AVG = 0,
                CALLS = 0,
                UOM = "MB/s"
            },
            WRITE =
            {
                OVERALLRECORDS = 0,
                CALLS = 0,
                AVGTIMEPEREXECUTE_MS = 0,
            }
        },
        RECENT = {}
    }
    return o
end
    
--merge the statistics given query with those of the past queries
function _ODBCStatistics:_mergestatistics(stats)
    self.data.CALLS = self.data.CALLS + 1
    if stats and type(stats)=='table' then
        self.data.RECENT = stats
        if stats.QUERY then
            self.data.PERFORMANCE.READ.CALLS = self.data.PERFORMANCE.READ.CALLS + 1
            self.data.PERFORMANCE.READ.OVERALLMB = self.data.PERFORMANCE.READ.OVERALLMB + stats.QUERY.BYTECOUNT/(1024*1024)
            self.data.PERFORMANCE.READ.OVERALLRECORDS = self.data.PERFORMANCE.READ.OVERALLRECORDS + stats.QUERY.RECORDCOUNT
            local tput = stats.QUERY.BYTEPERSECOND/(1024*1024)

            if self.data.PERFORMANCE.READ.CALLS == 1 then
                self.data.PERFORMANCE.READ.MIN = tput
                self.data.PERFORMANCE.READ.MAX = tput
                self.data.PERFORMANCE.READ.AVG = tput
            else
                if tput < self.data.PERFORMANCE.READ.MIN  then self.data.PERFORMANCE.READ.MIN = tput end
                if tput > self.data.PERFORMANCE.READ.MAX  then self.data.PERFORMANCE.READ.MAX = tput end
                -- rolling average is enough
                self.data.PERFORMANCE.READ.AVG = (self.data.PERFORMANCE.READ.AVG + tput)/2
            end
        elseif stats.EXECUTE then
            if stats.EXECUTE.ROWS_AFFECTED > 0 then
                self.data.PERFORMANCE.WRITE.OVERALLRECORDS = self.data.PERFORMANCE.WRITE.OVERALLRECORDS + stats.EXECUTE.ROWS_AFFECTED
            end
            self.data.PERFORMANCE.WRITE.CALLS = self.data.PERFORMANCE.WRITE.CALLS + 1
            if self.data.PERFORMANCE.WRITE.CALLS == 1 then
                self.data.PERFORMANCE.WRITE.AVGTIMEPEREXECUTE_MS = stats.EXECUTE.TIME
            else
                self.data.PERFORMANCE.WRITE.AVGTIMEPEREXECUTE_MS = (self.data.PERFORMANCE.WRITE.AVGTIMEPEREXECUTE_MS + stats.EXECUTE.TIME)/2
            end
        else
            error("Invalid stats table passed! " .. JSON.encode(stats))
        end
    end
end


function _ODBCStatistics:_get()
    return BUCKET.DEEPCOPY(self.data)
end



-- Class: a database Connection
local _ODBCConnection={}

_ODBCConnection.STATISTICS = nil

--this table is used to store the state and defaults
_ODBCConnection.STATE =
{
    DRIVER = nil,
    ENVIRONMENT = nil,
    CONNECTION = nil,
    CURSOR = nil,
    NAME = nil,
    DSN = nil,
    USER = "",
    PASSWORD = "",
    AUTOCLOSE = false,
    UTF8 = true,
    CODEPAGE = 0,
    MAXRECORDS = 100000,
    ITERMODE = 0, --or 1, 0: return records indexed by number as they appear in the query
    DRIVERMODULE = "luasql.odbc",
    --2: indexed by column name
    STATUS = 0,
    TIMETOOPEN = 0, --how long it took to open the connection
    OVERALLOPENTIME = 0
}

_ODBCConnection.STATUS=
{
    SQLERR = -12,
    DRIVERERR = -11,
    NODRIVER =- 2,
    NODSN = -1,
    NONE = 0,
    OPEN = 1,
    CLOSED = 2,
}


-- local r =_ODBCConnection:_new{
--     Name = args.Name,
--     DSN = args.DSN,
--     User = args.User,
--     Password = args.Password,
--     Autoclose = args.Autoclose,
--     utf8 = true, --to be cleared
--     Codepage = 0, --or args.Codepage --to be cleared
--     Maxrecords = args.Maxrecords,
--     Itermode = 0, --will be added
--     Parent = self,
-- }

_ODBCConnection.INFOS=
{
    VENDORNAME = '<unknown>',
    DRIVERNAME = '<unknown>',
    PRODUCTNAME = '<unknown>',
    INIT = false
}

-- converts a string from UTF-8 to ASCII
function _ODBCConnection:_ascii(s)
    --if self.utf8 then return s end
    --error("convert using codepage " .. tostring(self.codepage))
    local ret = ""
    local o, e = pcall(function() ret = inmation.utf8toascii(s) end)
    if not o then
        return s
    end
    return ret
end

-- converts all strings from the source to UTF-8
function _ODBCConnection:_utf8(s)
    --if self.utf8 then return s end
    --error("convert using codepage " .. tostring(self.codepage))
    local ret = ""
    local o, e = pcall(function() ret = inmation.asciitoutf8(s)end)
    if not o then
        return s
    end
    return ret
end

-- splits multi-line strings into a table as they are returned from ODBC drivers
-- (this rather belongs in a string utils library)
function _ODBCConnection:_splitstring(s, sep)
    local r={}
    sep=sep or '\n'
    s:gsub(string.format('([^%s]+)',sep), function(x) r[#r+1]=x end)
    return r
end

function _ODBCConnection:_breakodbcerror(s)
    local e = s
    local t = self:_splitstring(s,']')
    if #t==4 then
        self.INFOS.VENDORNAME = self.INFOS.VENDORNAME or t[1]:gsub('%[','') --Microsoft
        self.INFOS.DRIVERNAME = self.INFOS.DRIVERNAME or t[2]:gsub('%[','') --ODBC SQL Server Driver
        self.INFOS.PRODUCTNAME = self.INFOS.PRODUCTNAME or t[3]:gsub('%[','') --SQL Server
        e=t[4]
    end
    return e
end

-- UTF-8 conversion assumed to happened already
-- takes a  string and returns a table containing a structured error
function _ODBCConnection:_splitodbcerror(e)
    local r={}
    if "string"==type(e) and #e>0 then
        local t = self:_splitstring(e)
        for n=1,#t do
            table.insert(r, self:_breakodbcerror(t[n]))
        end
    end
    return r
end

-- tests the connection for vendor, driver, product
function _ODBCConnection:_initvendorinfo()
    local sql = "SELECT * FROM __1very2unlikely3to4exist__"
    local match = "%[([^%[^%]]-)%]%[([^%[^%]]-)%]%[([^%[^%]]-)%]" 
    local _, e = self.STATE.CONNECTION:execute(sql)    
    if e then
        --e = self:_utf8(tostring(e)):gsub("nil","")
        if type(e) == "string" and #e > 0  then
            local _, _, vendor, driver, product = string.find(e, match)
            self.INFOS.VENDORNAME = vendor or self.INFOS.VENDORNAME --Microsoft
            self.INFOS.DRIVERNAME = driver or  self.INFOS.DRIVERNAME--ODBC SQL Server Driver
            self.INFOS.PRODUCTNAME = product or  self.INFOS.PRODUCTNAME--SQL Server
            self.INFOS.INIT = true
        end  
    end
end


function _ODBCConnection:CONNECT()
    if self.STATE.STATUS == self.STATUS.OPEN then
        return self
    end
    local ms = inmation.currenttime()
    self.STATE.ENVIRONMENT = self.STATE.DRIVER:odbc()
    local err
    self.STATE.CONNECTION, err = self.STATE.ENVIRONMENT:connect(self.STATE.DSN, self.STATE.USER, self.STATE.PASSWORD)
    if self.STATE.CONNECTION then
        self.STATE.TIMETOOPEN = inmation.currenttime() - ms
        self.STATE.STATUS = self.STATUS.OPEN
        if not self.INFOS.INIT then
            self:_initvendorinfo() --could be made optional
            self.INFOS.INIT = true
        end
    else
        error("Could not open ODBC connection due to error " .. tostring(err), 2)
    end
    return self
end


function _ODBCConnection:CLOSE()
    if self.STATE.STATUS == self.STATUS.CLOSED then
        return nil
    else    
        local ok, err = pcall(function()
            self.STATE.CONNECTION:close() 
            self.STATE.CONNECTION = nil
            self.STATE.ENVIRONMENT:close()
            self.STATE.ENVIRONMENT = nil
            self.STATE.CURSOR = nil
            self.STATE.STATUS = self.STATUS.CLOSED
        end)
        if not ok then
            error("Could not close ODBC connection: " .. err, 2)
        end        
    end
end


function _ODBCConnection:SETITERMODE(mode)
    if not mode then
        error("Invalid mode!", 2)
    end
    if mode == 0 or mode == 1 then
        self.STATE.ITERMODE = mode
    end
end


function _ODBCConnection:EXECUTE(query)
    if self.STATE.STATUS == self.STATUS.CLOSED and not self.STATE.AUTOCLOSE then
        error("Cannot execute: Connection is closed!", 2)
    end

    if type(query)~="string" or #query==0 then 
        error("Invalid query " .. tostring(query) .. " provided of type " .. type(query), 2)
    end

    if self.STATE.STATUS == self.STATUS.CLOSED and self.STATE.AUTOCLOSE then
        self:CONNECT()
    end

    local r = {}
    
    r.DATA = {}
    local starttime = inmation.currenttime()
    r.STATISTICS = {}
    r.STATISTICS.STARTTIME = inmation.now()
    r.STATISTICS.STARTTIMELOCAL = inmation.gettime(inmation.currenttime(true)):gsub("Z","")
    r.STATISTICS.CONNECTION = BUCKET.DEEPCOPY(self.INFOS)

    local result = 0
    local execerr 
    self.STATE.CURSOR, execerr = self.STATE.CONNECTION:execute(self:_ascii(query))
    if self.STATE.CURSOR == nil and "string" == type(execerr) and #execerr > 0 then
        error("Error executing query " .. query .. ", Error: " .. tostring(execerr), 2)
    elseif self.STATE.CURSOR == nil and "string" == type(execerr) and #execerr == 0 then
        r.STATISTICS.EXECUTE = {}
        r.STATISTICS.EXECUTE.ROWS_AFFECTED = 0
        r.STATISTICS.EXECUTE.TIME = inmation.now() - starttime
        result = 1
    elseif self.STATE.CURSOR then
        if type(self.STATE.CURSOR) == "number" then --sql execute
            r.STATISTICS.EXECUTE = {}
            r.STATISTICS.EXECUTE.ROWS_AFFECTED = math.floor(self.STATE.CURSOR)
            r.STATISTICS.EXECUTE.TIME = inmation.now() - starttime
            result = 2
        else --cursor-returning query
            local records = 0
            local bytes = 0
            r.STATISTICS.QUERY = {}
            r.STATISTICS.QUERY.SQL = query
            r.STATISTICS.ROWCOUNT = 0
            r.STATISTICS.COLUMNS = {}
            r.STATISTICS.COLUMNS.NAMES = self.STATE.CURSOR:getcolnames()
            r.STATISTICS.COLUMNS.TYPES = self.STATE.CURSOR:getcoltypes()
            
            local row = self.STATE.CURSOR:fetch({}, 'n')
            while row do
                r.STATISTICS.ROWCOUNT = r.STATISTICS.ROWCOUNT + 1
                local dat = {}
                for i, v in ipairs(row) do
                    records = records + 1
                    if r.STATISTICS.COLUMNS.TYPES[i] == "string" then --format strings in utf8
                        if self.STATE.ITERMODE == 0 then
                            dat[i] = self:_utf8(v)
                        else
                            dat[r.STATISTICS.COLUMNS.NAMES[i]] = self:_utf8(v)
                        end
                        bytes = bytes + #v
                    else
                        if self.STATE.ITERMODE == 0 then
                            dat[i] = v
                        else
                            dat[r.STATISTICS.COLUMNS.NAMES[i]] = v
                        end
                        bytes = bytes + 8
                    end
                end
                records = records + 1
                table.insert(r.DATA, dat)
                row = self.STATE.CURSOR:fetch({}, 'n')
            end
            self.STATE.CURSOR:close()
            self.STATE.CURSOR = nil

            --check for unknown datatypes (PERHAPS DRIVER-DEPENDENT)
            for i=1, #r.STATISTICS.COLUMNS.NAMES do
                if r.STATISTICS.COLUMNS.TYPES[i] == nil then
                    error("Unknown datatype detected for column " ..  r.STATISTICS.COLUMNS.NAMES[i] .. " , consider converting types within the sql query: " .. query)
                end
            end

            result = 3

            r.STATISTICS.QUERY.RECORDCOUNT = records
            r.STATISTICS.QUERY.BYTECOUNT = bytes
            r.STATISTICS.QUERY.EXECUTIONTIMEMS = inmation.now() - starttime
            r.STATISTICS.QUERY.BYTEPERSECOND = 1000* bytes / r.STATISTICS.QUERY.EXECUTIONTIMEMS
        end
    end

    r.STATISTICS.ENDTIME = inmation.now()
    r.STATISTICS.ENDTIMELOCAL = inmation.gettime(inmation.currenttime(true)):gsub("Z","")
    self.STATISTICS:_mergestatistics(r.STATISTICS)

    if self.STATE.AUTOCLOSE then
        self:CLOSE()
    end

    if result == 1 then
        return 0, r.STATISTICS
    elseif result == 2 then
        return r.STATISTICS.EXECUTE.ROWS_AFFECTED, r.STATISTICS
    elseif result == 3 then
        return r.DATA, r.STATISTICS
    end 
end

-- creates a new Connection instance
--example:
-- local r =_ODBCConnection:_new{
--     Name = args.Name,
--     DSN = args.DSN,
--     User = args.User,
--     Password = args.Password,
--     Autoclose = args.Autoclose,
--     utf8 = true, --to be cleared
--     Codepage = 0, --or args.Codepage --to be cleared
--     Maxrecords = args.Maxrecords,
--     Itermode = 0, --will be added
--     Parent = self,
-- }
--input table args was typchecked by connection manager
function _ODBCConnection:_new(args)
    --local o = BUCKET.DEEPCOPY(self)

    local o = {}
    o.STATISTICS = BUCKET.DEEPCOPY(self.STATISTICS)
    o.STATE = BUCKET.DEEPCOPY(self.STATE)
    o.STATUS = BUCKET.DEEPCOPY(self.STATUS)
    
    --it was made sure in the connection factory that these fields exist
    o.STATE.NAME = args.Name
    o.STATE.DSN = args.DSN

    --set non-compulsory fields
    if args.User then o.STATE.USER = args.User end
    if args.Password then o.STATE.PASSWORD = args.Password end
    if args.Autoclose then o.STATE.AUTOCLOSE = args.Autoclose end
    if args.utf8 then o.STATE.UTF8 = args.uft8 end
    if args.Codepage then o.STATE.CODEPAGE = args.Codepage end
    if args.Maxrecords then o.STATE.MAXRECORDS = args.Maxrecords end
    if args.Itermode then o.STATE.ITERMODE = args.Itermode end

    --load driver (only once on connection creation)
    local ok, err = pcall(function()
        o.STATE.DRIVER = require(tostring(o.STATE.DRIVERMODULE))
        o.STATE.ENVIRONMENT = o.STATE.DRIVER:odbc()
    end)
    if not ok then
        error("Could not load driver " .. o.STATE.DRIVERMODULE .. ", error: " .. tostring(err), 3)
    end

    --set connection status
    o.STATE.STATUS = self.STATUS.NONE
    o.STATE.CONNECTION = nil
    o.STATE.CURSOR = nil

    --init statistics
    o.STATISTICS = _ODBCStatistics:_new()

    --driver is set on connection establishment
    --since input table args was typechecked

    self.__index = self
    local instance = setmetatable(o, self)
    
    --if autoclose is off, establish connection
    --otherwise, connection will be established on query execution
    if not self.STATE.AUTOCLOSE then
        local o, e = pcall(function() 
            instance:CONNECT()
        end)
        if not ok then 
            error("Could not establish connection: " .. e, 2)
        end
    end

    return instance
end


function _ODBCConnection:GETSTATISTICS()
    return self.STATISTICS:_get()
end


-- this library
local lib={}

-- required to be ESI
function lib.INFO()
    return {
        version = {
            major=0,
            minor=1,
            revision=1
        },
        contacts = {
            {
                name="Timo Klingenmeier",
                company="inmation Software GmbH",
                email="timo.klingenmeier@inmation.com",
            },
            {
                name="Sebastian Gau",
                email="sebastian.gau@basf.com",
            }
        },
        library = {
            modulename="esi-odbc",
            dependencies = {
                {
                    modulename = 'luasql.odbc',
                    version = 
                    {
                        major = 0,
                        minor = 1,
                        revision = 1
                    }
                },
                {
                    modulename = 'esi-bucket',
                    version =
                    {
                        major = 0,
                        minor = 1,
                        revision = 1
                    }
                },
            },
        }
    }
end

lib.MODE =
{
    NUMBERINDEX = 0,
    COLNAMEINDEX = 1
}


-- local dbobj = db:GETCONNECTION{
--     Name = "qawd", --can be set to standard value, is the identifier of the connection, internally the returned connection object is tracked in a table
--     DSN = "asd", --has to be provided
--     User = "asd", --can be set to standard value
--     Password = "pw", --can be set to standard value
--     Maxrecords = 1000, --can be set to standard value, how many records can be fetched at maximum in one query
--     Codepage = 0, --can be set to standard value,
--     Autoclose = false, --whether the connection is opened and closed on demand when executing a query, by default true
--     Itermode = db.MODE.NUMBERINDEX --also db.MODE.COLNAMEINDEX: determines whether the tableiterator returns a lua table whose keys are numbers (0) or the column names
-- }
--or if a connection
lib.connections = {} --holds the connection objects 
function lib:GETCONNECTION(args)
    if type(args)~="table" and type(args)~="string" then
        error("Invalid type for argument table: " .. type(args), 2)
    end

    --return object from the connection pool if one is availible (simplified syntax)
    if type(args) == "string" and #args > 0 and self.connections[args] then
        if not self.connections[args] then
            error("Connection with name " .. args .. " is not availible!")
        else
            return self.connections[args]
        end
    end

    -- error checks
    if args.Name and type(args.Name)~="string" then
        error("Invalid argument for Name: " .. type(args.Name), 2)
    end

    --return object from the connection pool if one is availible
    if args.Name and self.connections[args.Name] then
        return self.connections[args.Name]
    end

    if not args.DSN then error("Argument table is missing compulsory field DSN!", 2) end
    if type(args.DSN) ~= "string" then
        error("No valid DSN provided in input table: " .. type(args.DSN), 2)
    end
    if args.User and type(args.User) ~= "string" then
        error("Invalid User provided in input table!", 2)
    end
    if args.Password and type(args.Password) ~= "string" then
        error("Invalid Password provided in input table!", 2)
    end
    if args.Maxrecords and type(args.Maxrecords) ~= "number" then
        error("Invalid Maxrecords provided in input table!", 2)
    end
    if args.Autoclose and type(args.Autoclose) ~= "boolean" then
        error("Invalid Autoclose field provided in input table!", 2)
    end
    if args.Itermode and type(args.Itermode) ~= "number" then
        error("Invalid Itermode field provided in input table!", 2)
    end
    if args.Driver and type(args.Driver) ~= "string" then
        error("Invalid Driver provided in input table!", 2)
    end


    --if mode is on autoclose, the connection will not be added to the connection pool
    if not args.Name then
        args.Autoclose = true
    end

    local r = _ODBCConnection:_new{
        Name = args.Name,
        DSN = args.DSN,
        User = args.User,
        Password = args.Password,
        Autoclose = args.Autoclose,
        utf8 = true, --to be cleared
        Codepage = 0, --to be cleared
        Maxrecords = args.Maxrecords,
        Itermode = args.Itermode,
        Parent = self,
    }

    --add to connection pool
    if not args.Autoclose then
        self.connections[args.Name] = r
    end

    return r
end

return lib