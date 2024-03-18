local mq = require('mq')
local runscript = true

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

local function levelScibe(level, target_name)
	if target(target_name) then
		mq.cmdf("/say #level %d", level)
		mq.cmdf("/say #scribespells %d", level)
	end
end

mq.bind("/lvl", levelScibe)


while runscript do
	mq.delay(5000)
end