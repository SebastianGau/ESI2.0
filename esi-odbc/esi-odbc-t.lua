-- esi-odbc

-- Scope: The collection of statistical information about ODBC calls in this library
local _ODBCStatistics={
    data = {},

    _prec = function(self, num, prec)
        prec=prec or 2
        return tonumber(string.format(string.format("%%.%df",prec),num))
    end,

    _take = function(self, name, stats)
        if not self.data then
            self.data={}
            self.data.START=inmation.currenttime()
            self.data.STARTLOCAL=inmation.gettime(inmation.currenttime(true)):gsub("Z","")
            self.data.CALLS=0
            self.data.PERFORMANCE={UOM="MB/sec"}
            self.data.QUERIES={}
            self.data.EXECUTES={}
            self.data.RECENT={}
        end
        self.data.CALLS=self.data.CALLS+1
        --if 1<self.data.CALLS then
        --    error("Calls: " .. self.data.CALLS)
        --end
        if stats then
            self.data.RECENT.END=inmation.currenttime()
            self.data.RECENT.ENDLOCAL=inmation.gettime(inmation.currenttime(true)):gsub("Z","")
            self.data.RECENT.NAME=name
            self.data.RECENT.DATA=stats
            if stats.QUERY then
                -- performance is updated for error-free calls
                self.data.PERFORMANCE.READ=self.data.PERFORMANCE.READ or {START=self.data.RECENT.END,END=self.data.RECENT.END,MB=0,CALLS=0,MIN=0,MAX=0,AVG=0}
                if not stats.QUERY.ERROR then
                    -- two digits precision is enough
                    self.data.PERFORMANCE.READ.MB=self:_prec(self.data.PERFORMANCE.READ.MB+stats.QUERY.BYTES/(1024*1024))
                    local tput=self:_prec(stats.QUERY.BYTES/(stats.QUERY.MS/1000)/(1024*1024))
                    self.data.PERFORMANCE.READ.CALLS=self.data.PERFORMANCE.READ.CALLS+1
                    if 1==self.data.PERFORMANCE.READ.CNT then
                        self.data.PERFORMANCE.READ.MIN=tput
                        self.data.PERFORMANCE.READ.MAX=tput
                        self.data.PERFORMANCE.READ.AVG=tput
                    else
                        self.data.PERFORMANCE.READ.END=self.data.RECENT.END
                        if self.data.PERFORMANCE.READ.MIN>tput then self.data.PERFORMANCE.READ.MIN=tput end
                        if self.data.PERFORMANCE.READ.MAX<tput then self.data.PERFORMANCE.READ.MAX=tput end
                        -- rolling average is enough
                        self.data.PERFORMANCE.READ.AVG=self:_prec((self.data.PERFORMANCE.READ.AVG+tput)/2)
                    end
                end
            elseif stats.EXECUTE then

            end
        end
    end,

    _get = function(self, recent)
        local ret={}
        if not recent then 
            if self.data then ret=self.data end
        else
            if self.data.RECENT then ret=self.data.RECENT end
        end
        return ret
    end
}


-- Class: a database Connection
local _ODBCConnection={}
_ODBCConnection.autoclose = nil

_ODBCConnection.STATUS=
{
    SQLERR=-12,
    DRIVERERR=-11,
    NODRIVER=-2,
    NODSN=-1,
    NONE=0,
    OPEN=1,
    CLOSED=2,
}

_ODBCConnection.DEFAULTS=
{
    MAXRECORDS=100000,
    CODEPAGE=0,
}

_ODBCConnection.INFOS=
{
    VENDORNAME = '<unknown>',
    DRIVERNAME = '<unknown>',
    PRODUCTNAME = '<unknown>'
}

_ODBCConnection.ACCESS =
{
    DSN = "",
    USER = "",
    PASSOWRD = ""
}

-- converts a string from UTF-8 to ASCII
function _ODBCConnection:_ascii(s)
    --if self.utf8 then return s end
    --error("convert using codepage " .. tostring(self.codepage))
    return inmation.utf8toascii(s,self.codepage)
end

-- converts all strings from the source to UTF-8
function _ODBCConnection:_utf8(s)
    --if self.utf8 then return s end
    --error("convert using codepage " .. tostring(self.codepage))
    return inmation.asciitoutf8(s,self.codepage)
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
    local e=s
    local t=self:_splitstring(s,']')
    if #t==4 then
        self.INFOS.VENDORNAME = '<unknown>' or t[1]:gsub('%[','') --Microsoft
        self.INFOS.DRIVERNAME = '<unknown>' or t[2]:gsub('%[','') --ODBC SQL Server Driver
        self.INFOS.PRODUCTNAME = '<unknown>' or t[3]:gsub('%[','') --SQL Server
        e=t[4]
    end
    return e
end

-- tests the connection for vendor, driver, product
function _ODBCConnection:_getvendorinfo()
    local sql="SELECT * FROM __1very2unlikely3to4exist__"
    local c,e=self.con:execute(sql)    
    if e then
        e=self:_utf8(tostring(e)):gsub("nil","")
        if "string"==type(e) and 0<#e then
            local t=self:_splitstring(e)
            for n=1,#t do
                self:_breakodbcerror(t[n])
                break
            end
        end
    end
end

-- UTF-8 conversion assumed to happened already
-- takes a  string and returns a table containing a structured error
function _ODBCConnection:_splitodbcerror(e)
    local r={}
    if "string"==type(e) and #e>0 then
        local t=self:_splitstring(e)
        for n=1,#t do
            table.insert(r, self:_breakodbcerror(t[n]))
        end
    end
    return r
end

-- opens the connection
function _ODBCConnection:_open(setvendor)
    local ms=inmation.currenttime()
    self.env=self.driver:odbc()
    self.con,self.openerror=self.env:connect(self.dsn,self.user,self.pwd)
    if self.con then
        self.opentime=inmation.currenttime()-ms
        self.state=self.STATUS.OPEN
        if setvendor then 
            self:_getvendorinfo() 
        end
    else
        o.lerr=o.lerr or self.openerror
    end
end

-- closes the connection
function _ODBCConnection:_close()
    if self.con then
        local ok, err = pcall(function()
            self.con:close(); self.con=nil
            self.env:close(); self.env=nil
            self.state=self.STATUS.CLOSED
        end)
        if not ok then
            error("Could not close ODBC connection: " .. err, 3)
        end        
    end
end

-- fetches all records and returns a table
function _ODBCConnection:_query2table(sql)
    local r={}
    r.STATISTICS={}
    r.STATISTICS.CONNECTION={
        OPEN=nil~=self.con,
        VENDOR=self.vendorname or '<unknown>',
        DRIVER=self.drivername or '<unknown>',
        PRODUCT=self.productname or '<unknown>',
        MS=self.opentime,
        ERROR=self:_utf8(tostring(self.openerror)):gsub("nil","")
    }
    r.STATISTICS.QUERY={SQL=sql}
    r.STATISTICS.COLUMNS={}
    r.DATA={}
    if self.con then
        local ms=inmation.currenttime()
        -- run the query
        self.cursor,self.queryerror=self.con:execute(sql)
        if "string"==type(self.queryerror) and 0<#self.queryerror then
            r.STATISTICS.QUERY.ERROR={NATIVE=self:_utf8(tostring(self.queryerror)):gsub("nil","")}
            local errt=self:_splitstring(r.STATISTICS.QUERY.ERROR.NATIVE)
            r.STATISTICS.QUERY.ERROR.LIST={}
            for n=1,#errt do
                table.insert(r.STATISTICS.QUERY.ERROR.LIST,self:_breakodbcerror(errt[n]))
            end
        end
        local recs=0
        local bytes=0
        if self.cursor then
            r.STATISTICS.COLUMNS.NAMES=self.cursor:getcolnames()
            r.STATISTICS.COLUMNS.TYPES=self.cursor:getcoltypes()
            repeat
                local rec=self.cursor:fetch({},"n")
                if rec then
                    local dat={}
                    for i,v in ipairs(rec) do
                        if "string"==r.STATISTICS.COLUMNS.TYPES[i] then
                            dat[r.STATISTICS.COLUMNS.NAMES[i]]=self:_utf8(v)
                            bytes=bytes+#v
                        elseif "number"==r.STATISTICS.COLUMNS.TYPES[i] then
                            dat[r.STATISTICS.COLUMNS.NAMES[i]]=v
                            bytes=bytes+8
                        end
                    end
                    recs=recs+1
                    table.insert(r.DATA,dat)
                end
            until not rec or recs>=self.maxrecords
            self.cursor:close()
        end
        r.STATISTICS.QUERY.RECORDS=recs
        r.STATISTICS.QUERY.BYTES=bytes
        ms=inmation.currenttime()-ms
        r.STATISTICS.QUERY.MS=ms
        if self.autoclose then
            self:_close()
        end
    end
    r.ERROR=self.lerr
    return r
end

-- executes a table of SQL
--sqltable is a ordered lua table with sql statements as strings
--sqltable = {"SELECT * FROM IDONTKNOW", "EXECUTe usp_dosomething"}
--returns a table with fields DATA and  ERROR
--DATA is a ordered table with result entries, i.e.
--DATA =
-- {
--     [1] = {columnname = valueofthiscolumn},
--     [2] = {columnname = valueofthiscolumn}
-- }
function _ODBCConnection:_execute(sqltable)
    local r={}
    r.STATISTICS={CMD="_execute"}
    r.STATISTICS.CONNECTION={
        OPEN=nil~=self.con,
        VENDOR=self.vendorname or '<unknown>',
        DRIVER=self.drivername or '<unknown>',
        PRODUCT=self.productname or '<unknown>',
        MS=self.opentime,
        ERROR=self:_utf8(tostring(self.openerror)):gsub("nil","")
    }
    r.STATISTICS.EXECUTE={ROWS_AFFECTED=0,BATCH=#sqltable}
    r.DATA={}
    if self.con then
        local ms=inmation.currenttime()
        -- run the queries
        for n=1,#sqltable do
            self.cursor,self.execerror=self.con:execute(self:_ascii(sqltable[n]))
            if "string"==type(self.execerror) and 0<#self.execerror then
                error("exec=" .. tostring(self.execerror))
                r.STATISTICS.EXECUTE.ERROR={NATIVE=self:_utf8(tostring(self.execerror)):gsub("nil","")}
                local errt=self:_splitstring(r.STATISTICS.EXECUTE.ERROR.NATIVE)
                r.STATISTICS.EXECUTE.ERROR.LIST={}
                for n=1,#errt do
                    table.insert(r.STATISTICS.EXECUTE.ERROR.LIST,self:_breakodbcerror(errt[n]))
                end
            elseif self.cursor then
                if "number"==type(self.cursor) then
                    r.STATISTICS.EXECUTE.ROWS_AFFECTED=r.STATISTICS.EXECUTE.ROWS_AFFECTED+math.floor(self.cursor)
                else
                    r.STATISTICS.COLUMNS.NAMES=self.cursor:getcolnames()
                    r.STATISTICS.COLUMNS.TYPES=self.cursor:getcoltypes()
                    repeat
                        local rec=self.cursor:fetch({},"n")
                        if rec then
                            local dat={}
                            for i,v in ipairs(rec) do
                                if "string"==r.STATISTICS.COLUMNS.TYPES[i] then
                                    dat[r.STATISTICS.COLUMNS.NAMES[i]]=self:_utf8(v)
                                    bytes=bytes+#v
                                elseif "number"==r.STATISTICS.COLUMNS.TYPES[i] then
                                    dat[r.STATISTICS.COLUMNS.NAMES[i]]=v
                                    bytes=bytes+8
                                end
                            end
                            recs=recs+1
                            table.insert(r.DATA,dat)
                        end
                    until not rec or recs>=self.maxrecords
                    self.cursor:close()
                end
            end
        end
    end
    r.ERROR=self.lerr
    return r
end

-- creates a new Connection instance
--example:
-- r=_ODBCConnection:_new{
--     name=conn.NAME,
--     dsn=conn.DSN,
--     user=conn.USER,
--     pwd=conn.PWD,
--     driver=self.odbc,
--     autoopen=true,
--     autoclose=not conn.NAME,
--     utf8=conn.UTF8,
--     codepage=conn.CP or 0,
--     maxrecords=conn.MAXRECORDS
-- }
function _ODBCConnection:_new(o)
    o = o or {}
    o.state=self.STATUS.NONE
    o.curs=nil
    if "number" ~= type(o.maxrecords) then o.maxrecords=self.DEFAULTS.MAXRECORDS end
    if "number" ~= type(o.codepage) then o.codepage=self.DEFAULTS.CODEPAGE end
    if not o.driver then o.state=self.STATUS.NODRIVER; o.lerr="No ODBC driver specified" end
    if not o.dsn then o.state=self.STATUS.NODSN; o.lerr="No DSN specified" end
    if not o.name then o.name=o.dsn end
    if nil==o.test then o.test=true else o.test=true==o.test end
    self.__index = self
    local instance=setmetatable(o,self)
    -- open the connection
    instance:_open(o.test)
    -- test the connection only once
    o.test=o.test and self.STATUS.OPEN~=o.state
    return instance
end

-- this library
local lib={}
lib.odbc=require('luasql.odbc')

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
                email="timo.klingenmeier@inmation.com"
            }
        },
        library = {
            modulename="esi-odbc",
            filename="lib-esi-odbc.lua",
            description=[[--
            esi-odbc offers the most simple interface to fetch table or view data from external database servers.
            There are functions for open-fetch-close like QUERYDATA and open-insert-close using EXECUTE.
            The ODBCMerge class allows for MERGE (upsert) definitions. MERGE does not work with all RDBMS 
            (it does work with MS SQL Server, but not with MySQL).
            The libary takes also care about string conversions according to the default (or specified) code table.
            Errors which might have occured during one call sequence can be obtained from the STATISTICS call.
            --]]
        }
    }
end

-- helper to set up the connection
--this bascially implements a simple connection pooling
--conn: an _ODBCConnection object
--creates a new _ODBCConnection object and returns it
function lib:_getconnection(conn,sql)
    local r
    -- error checks
    if not conn or not sql then return {},"both 'conn' and 'sql' must be supplied for the call" end
    if "string" ~= type(sql) then return {},"'sql' must be a valid SQL string" end
    if "string" == type(conn) and not self.connections[conn] then return {},("'conn' given as string, parsing not yet implemented") end
    -- test conn parameter
    if "table" == type(conn) then
        if "function" == type(conn._new) then
            -- reuse an existing connection
            r=conn
        else
            -- test whether we already have a connection object
            self.connections=self.connections or {}
            if conn.NAME and self.connections[conn.NAME] then
                r=self.connections[conn.NAME]
            else
                -- create a connection, autoclose if no name was given
                r=_ODBCConnection:_new{
                    name=conn.NAME,
                    dsn=conn.DSN,
                    user=conn.USER,
                    pwd=conn.PWD,
                    driver=self.odbc,
                    autoopen=true,
                    autoclose=not conn.NAME,
                    utf8=conn.UTF8,
                    codepage=conn.CP or 0,
                    maxrecords=conn.MAXRECORDS
                }
                if not r.autoclose then
                    self.connections[conn.NAME]=r
                end
            end
        end
    elseif "string"==type(conn) then
        r=self.connections[conn]
    end
    return r    
end

-- allows to fetch data in a Lua table with autocreation (and autoclose option) of the odbc connection
-- the result can be returned as a Lua table (default) or as a JSON document
--argument conn: mandatory, an _ODBCConnection object returned by _new
--argument sql: mandatory, a string holding
--argument json can be nil, if non-nil the lib returns a
function lib:QUERYDATA(conn, sql)
    local actconn, err=self:_getconnection(conn,sql)
    -- connection functional?
    if actconn and actconn.state == _ODBCConnection.STATUS.OPEN then
        local ret=actconn:_query2table(sql)
        _ODBCStatistics:_take(actconn.name, ret.STATISTICS) --saves statistics of the query
        -- save the connection, if it is not autoclosing
        if not actconn.autoclose then
            self.recentconnection=actconn
        end
        return ret.DATA,ret.ERROR
    else
        if err then return {},err else return {},"unknown error creating or obtaining ODBC connection" end
    end
end

-- executes a single or multiple SQL commands
--argument conn: mandatory
--argument sql: mandatory
function lib:EXECUTE(conn,sql)
    local actconn=self:_getconnection(conn,sql)
    -- connection functional?
    if actconn and _ODBCConnection.STATUS.OPEN==actconn.state then
        if "string"==type(sql) then
            local s=sql
            sql={}
            table.insert(sql,s)
        end
        -- invoke the low-level execution
        local ret=actconn:_execute(sql)
        _ODBCStatistics:_take(actconn.name, ret.STATISTICS)
        -- save the connection, if it is not autoclosing
        if not actconn.autoclose then
            self.recentconnection=actconn
        end
        return ret.DATA
    else
        if err then return err else return "unknown error creating or obtaining ODBC connection" end
    end
end

-- get all or recent statistics, either as a table or as a JSON document
function lib:GETSTATISTICS(recent)
    local ret=_ODBCStatistics:_get(recent)
    return ret
end

return lib