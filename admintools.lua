local mq = require('mq')
local runscript = true

if not table.unpack then table.unpack = unpack end

local sets = {}

sets["DefiantArmor"] = { 50033, 50034, 50035, 50036, 50037, 50038, 50039 }
sets["DeffiantRobes"] = { 50060, 50059, 50552, 50057, 50056, 50055, 50058, 50054}
sets["DefWAR"] = { 50532, table.unpack(sets["DefiantArmor"])}
sets["DefCLR"] = { 50541, table.unpack(sets["DefiantArmor"])}
sets["DefNEC"] = { 50541, table.unpack(sets["DeffiantRobes"])}
sets["FND"] = { 76346, 56749 }
-- END OF SETS

local function target(target_name)
	if target_name then 
		mq.cmdf("/target \"%s\"", target_name)
		mq.delay(100)
	else
		if mq.TLO.Target() then
			return true
		else
			print("Not targeting anything")
			return false
		end
	end

	if not mq.TLO.Target()
		or not mq.TLO.Target.Name() == target_name then
		printf("\"%s\" is not a valid target", target_name)
		return false
	else
		return true
	end
end

local function levelScibe(level, targ_name)
	if target(targ_name) then
		mq.cmdf("/say #level %d", level)
		mq.cmdf("/say #scribespells %d", level)
	end
end

local function getItemSet(set_name, cnt, targ_name)
	if target(targ_name) then
		local set = sets[set_name]
		if set then
			for i=1, cnt do
				for i, ID in ipairs(set) do
					mq.cmdf("/say #gi %d", ID)
				end
			end
		else
			printf("Invalid set name: %s", set_name)
		end
	end
end

mq.bind("/lvl", levelScibe)
mq.bind("/giveset", getItemSet)


while runscript do
	mq.delay(5000)
end