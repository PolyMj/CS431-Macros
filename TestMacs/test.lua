local mq = require('mq')

local runscript = true
local spell = nil

local callback = function(arg1)
	print("Callback function")
	printf("Arg1 = %s", arg1)
end

local memspellset = function(spellset)
	mq.cmdf('/memspellset %s', spellset)
end

local setspell = function(gemid)
	spell = mq.TLO.Me.Gem(gemid)
	printf("Spell is %s", spell.Name())
end

local castspell = function()
	if spell ~= nil then
		mq.cmdf('/cast "%s"', spell.Name())
	end
end

mq.bind('/tcb', callback)
mq.bind('/mss', memspellset)
mq.bind('/setspell', setspell)
mq.bind('/cst', castspell)

local iterate_group = function()
	local size = mq.TLO.Group.GroupSize()
	printf("%d members in my group", size)

	local tank = mq.TLO.Group.MainTank()
	if tank then
		printf("Main Tank is %s", tank)
	else
		print("No Main Tank, searching for a tank...")
		for i in range(0, size) do
			local member = mq.TLO.Group.Member(i)
			local class = member.Class()
			if (class == "SHD" or class == "PAL" or class == "WAR") then
				printf("%s is a tank", member.Name())
				break
			end
		end
	end

	local assist = mq.TLO.Group.MainAssist()
	if assist then
		printf("Main Assist is %s", assist)
	else
		printf("No Main Assist")
	end
end

mq.bind('/itg', iterate_group)


while runscript do
	printf("Test")
	--mq.cmd('/sit')
	mq.delay(1000)
end