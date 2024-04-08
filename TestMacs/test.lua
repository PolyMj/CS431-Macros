local mq = require('mq')

local runscript = true
local spell = nil
local tank = nil

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

	tank = mq.TLO.Group.MainTank()
	if tank then
		printf("Main Tank is %s", tank)
	else
		print("No Main Tank, searching for a tank...")
		for i=0, size do
			local member = mq.TLO.Group.Member(i)
			local class = member.Class.ShortName()
			print(class)
			if (class == "SHD" or class == "PAL" or class == "WAR") then
				printf("%s is a tank", member.Name())
				tank = member
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

local found_spawns = nil

local function spawnCond(spawn)
	return (
		spawn.Distance3D() < 300
		and spawn.Type() == 'NPC'
		and spawn
	)
end

local function findEnemyISS()
	found_spawns = mq.getFilteredSpawns(spawnCond)
	if mq.TLO.Target() then
		printf("Distance from target is %f", mq.TLO.Target.Distance3D())
	end
end

local function FindEnemyMQ2()
	print("Looking for xtargets...")
	local cond_str = ", npc"
	i = 0
	local sp = mq.TLO.NearestSpawn(1, cond_str)
	if not sp.Name() then print("No targets found") end

	while sp.Name() do
		mq.cmdf("/target \"%s\"", sp.Name())
		printf("Targeting %s", sp.Name())
		i = i + 1
		sp = mq.TLO.NearestSpawn(i, cond_str)
		mq.delay(400)
	end
	
end

mq.bind('/fenemy', findEnemyISS)

local index = 0
local function iterateSpawns()
	if not found_spawns then return end

	for key, value in ipairs(found_spawns)
	do
		mq.cmdf("/target \"%s\"", value.Name())
		printf("Targeting %s", value.Name())
		mq.delay(1000)
	end
end

mq.bind('/itenemy', iterateSpawns)

iterate_group()
if tank then printf("Tank is %s", tank.Name())
else print("No tank") end

local function itXTargets()
	local cnt = mq.TLO.Me.XTarget()
	printf("%d XTargets", cnt)
	for i=1, cnt do
		local targ = mq.TLO.Me.XTarget(i)
		if targ.Name() then
			printf(targ.Name())
			mq.delay(20)
		else
			print(i)
		end
	end
end


while runscript do
	-- FindEnemyMQ2()
	itXTargets()
	-- print(mq.TLO.Cast.Ready("Yaulp II"))
	mq.delay(1500)
end