local CAT = require 'esi-catalog'
local JSON = require 'dkjson'

local o = CAT:FIND("ObjectName", "System")
local names = {}
for i=1, #o do
    table.insert(names, o[i]:path())
end

local o = CAT:FIND({"ObjectName"}, {"System"}) --equality operator is assumed
local names1 = {}
for i=1, #o do
    table.insert(names1, o[i]:path())
end

local o = CAT:FIND({"ObjectName"}, {"System"}, {"="})
local names2 = {}
for i=1, #o do
    table.insert(names2, o[i]:path())
end

if not #names == #names1 or not #names1 == #names2 then
    error("There should be an equal number of results!")
end

return "Objects found with name 'System': " .. JSON.encode(names)