--deploy-example
-- HX Template version 0.3
-- MorenoF5, 20170425
-- inlcude VKPI (for automatic kpi definition)

-- This script deploys a heat exchanger model

-- !!!!IMPORTANT
-- even if some of the tables defined below are not needed (e.g. no user_defined_kpi is present), the table must be defined, but left empty, e.g.
-- user_defined_kpi = {}


-- Enter the full path to the datasource here
-- "/System/Core/Connector/inmation.ProductiveCore.OPCServer.1" is the path in the TestSystem. delete it to get the path of the productive system
local plantpath = "/System/Core/EMEA-LU-V154-PIMS/Aspen.Infoplus21_DA.1/Use Cases/PredM/W935"
-- if more than one data source (reading from several pims), add source = planth_path for the deviating signals in the t table. Those without a "source" field/key, will use the path from
-- plantpath
local plantpath2= "/System/Core/Connector/inmation.ProductiveCore.OPCServer.1/System/AMCPM-Core/EMEA-LU-V154-PIMS/Aspen.Infoplus21_DA.1"


-- Averaging Time for the input values. if no filtering is desired, set to nil or false
local averagingTime = 5*60*1000 -- the time which should be used for averaging in ms (example: 1hour*60minutes*60seconds*1000ms, for 1 hour average)
-- make moving_average true if moving average is desired. otherwise, false
local Moving_Average = true

-- This table specifies the whole input data
-- mandatory informations: alias, tag
-- Use the standard aliases as defined in the standardcalculations (see end of script) if possible.
-- off_condition: it compares the alias variable with the limit defined with this key. If several rows contain an off_conditions, 
-- the OR combination of all these rows will be used
-- if single tags should not be averaged, use small time for buffer (1 second e.g.) this just copies the actual value to the filtered folder
t = {
	 {type = "inputs",alias = "Tci",  tag = "T8214",     minlim = 0,    maxlim = 200,     eu = "°C",    buffer = averagingTime, MA = Moving_Average},
	 {type = "inputs",alias = "Tco",  tag = "T8225",     minlim = 0,    maxlim = 200,     eu = "°C",    buffer = averagingTime, MA = Moving_Average},
	 {type = "inputs",alias = "Thi",  tag = "T8201",     minlim = 0,    maxlim = 200,     eu = "°C",    buffer = averagingTime, MA = Moving_Average},
  	 {type = "inputs",alias = "Tb",   tag = "T8213",     minlim = 0,    maxlim = 200,     eu = "°C",    buffer = averagingTime, MA = Moving_Average},
  	 {type = "inputs",alias = "Fh",   tag = "F8216",     minlim = 0,    maxlim = 2000,    eu = "m³/h",  buffer = averagingTime, MA = Moving_Average, off_condition = "< 100"},
     {type = "inputs",alias = "Fb",   tag = "F8207",     minlim = 0,    maxlim = 2000,    eu = "m³/h",  buffer = averagingTime, MA = Moving_Average}, 
	 {type = "inputs",alias = "Pho",  tag = "P8218",     minlim = 0,    maxlim = 10,      eu = "bar",   buffer = averagingTime, MA = Moving_Average},
	 {type = "inputs",alias = "F_hCl",  tag = "F4552",     minlim = 0,    maxlim = 10,      eu = "m³/h",   buffer = averagingTime, MA = Moving_Average, off_condition = ">0.1"},
} 
	 
-- const contains additional constant parameters, needed for the calculation of heat exchange coefficients
const = {
	{type = "const",  alias = "Cph" ,   value = 4.184, eu = "MJ/ton K"},
	{type = "const",  alias = "Cpc" ,   value = 4.184, eu = "MJ/ton K"},
  	{type = "const",  alias = "Area",   value = 662,   eu = "m2"}			
}

-- if one process input needs be calculated from some other tags, the formula should be included here.
--	input calculations also can be used to define more complicated deactivation conditions
-- to add more than one "adv_off_condition" add numbers to the alias (e.g. "adv_off_condition2", etc.)
input_calculations = {
	{type = "user_input",alias = "Tho",formula = "((Fb*Tb)-((Fb-Fh)*Thi)) / Fh",  minlim = 0, maxlim = 200, eu = "°C",  ""},
	}

-- for any kind of kpi beyond those defined by default, the alias (name) and formula should be defined here, following the next example.
user_defined_kpi ={ {type = "user-kpi", alias = "P_KPI", formula = "Pho+0.002*(350-Fh)"},
					{type = "user-kpi", alias = "P_Signal", formula = "Pho"}}
-- additionally, all variables (alias + all inputs in the formulas), must be listed in user_defined_kpi_list
user_defined_kpi_list = {"P_Signal"}

-- define which kpi calculations should be deployed as kpi-objects, accessible from Transpara.
-- objname: name of the kpi in the I/O model (or for user_defined_kpi, ALIAS)
-- displayname: name that will be shown in transpara for the object
-- low, high: alarm limits for the display: additional possibilities are
-- lowlowlow, lowlow, low, target, high, highhigh, highhighhigh
-- eu: allows to add Engineering Units which will be displayed in VKPI
VKPI = {
  { objname = "P_Signal", displayname = "dP", min = 0.2, max = 0.4, eu = "bar" },
  { objname = "P_KPI", displayname = "dP_korrigiert", min = 0.1, max = 0.5, eu = "bar" },
}

-- *********************** DONT CHANGE *****************

local cwd = inmation.getparentpath(inmation.getselfpath())
local HX = require"PredM.HX"
return HX.deployHX(plantpath,cwd,t,const,input_calculations,user_defined_kpi,user_defined_kpi_list,VKPI)


-- List of standardcalculations which will always be deployed, if the needed input Parameters are available:
--			DTc = Tco-Tci
--			DTh = Thi-Tho
--  		DT1 = Tho-Tci
--			DT2 = Thi-Tco
--			DTML = (DT1-DT2)/math.log(DT1/DT2)
--			Qdotc = Fc*DTc*Cpc
--			Qdoth = Fh*DTh*Cph
--			UAc = Qdotc / DTML
--			nvUAc = DTML / Qdotc
--			UAh = Qdoth / DTML
--			invUAh = DTML / Qdoth
--			Uh = UAh / Area
--			Uc = UAc / Area
--			dPc_calc = Pco - Pci
--			dPh_calc = Pho - Phi
--			dPh_calc_fh2 = (Pho - Phi)/(Fh^2)
--			dPc_calc_fc2 = (Pco - Pci)/(Fc^2)
--			dPh_fh2 = (dPh)/(Fh^2)
--			dPc_fc2 = (dPc)/(Fc^2)
