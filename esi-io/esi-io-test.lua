local IO = require 'esi-io'
IO:ENSUREFOLDER("", "foldername", "folderdesc")
IO:ENSUREHOLDER("", "holdername", "folderdesc", "unit", {Custom = { asd = "asd"}})
IO:ENSUREACTIONITEM("", "itemname", "desc", "local a = 3 return a", true, {Custom = { asd = "asd"}})
return "passed"