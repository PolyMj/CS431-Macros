local mq = require('mq')
local runscript = true

-- Exit if not a healer
if (not mq.TLO.Me.Class.HealerType()) then
	print("Not a healer, exiting...")
else
	print("You are a healer")
end

local tank = nil
local me_spawn = mq.TLO.Spawn(mq.TLO.Me.ID())

local TANK_HEAL_TH = 80
local SELF_HEAL_TH = 90
local OTHER_HEAL_TH = 50

local ATK_MANA_TH = 80
local DEBUFF_MANA_TH = 50


-- Get spells
local heal_spell = mq.TLO.Me.Gem(1)
local buff_spell_1 = mq.TLO.Me.Gem(2)
local buff_spell_2 = mq.TLO.Me.Gem(3)
local attack_spell = mq.TLO.Me.Gem(4)
local debuff_spell = mq.TLO.Me.Gem(5)

printf("Healing spell: %s", heal_spell.Name())
printf("Buff spell 1: %s", buff_spell_1.Name())
printf("Buff spell 2: %s", buff_spell_2.Name())
printf("Attack spell: %s", attack_spell.Name())
printf("Debuff spell: %s", debuff_spell.Name())

local MQ_FALSE = mq.TLO.Cast.Ready("NOT A SPELL")

-- Targets the given target, or untargets if given nil target
local function target(targ)
	if targ then
		mq.cmdf("/target \"%s\"", targ.Name())
		return true
	else
		print("Nil target, untargeting")
		mq.cmd("/target")
		return false
	end
end

-- Finds a tank in your group
local function findTank()
	-- Check prerequisites (is grouped)
	if (not mq.TLO.Me.Grouped()) then
		print("Not in a group")
	else
		printf("In a group with %d members, finding tank...", mq.TLO.Group.GroupSize())
	end

	-- Iterate through group members, checking their classes
	for i = 0, mq.TLO.Group() do
		local member = mq.TLO.Group.Member(i)
		local class = member.Class.ShortName()
		if class == "WAR" or class == "PAL" or class == "SHD" then
			printf("  %s is a tank (%s)", member.Name(), class)
			tank = member
		else
			printf("  %s is not a tank (%s)", member.Name(), class)
		end
	end

	-- If a tank was found, print the tanks name. Otherwise, script should end
	if (tank) then
		printf("Chosen tank is %s (%s)", tank.Name(), tank.Class.ShortName())
	else
		print("No tank was found, ending macro...")
		runscript = false
	end
end

-- Checks if the target has the given buff (spell)
local function hasBuff(spell, targ)
	local val = targ.Buff(spell.Name()).ID()
	return val
end

-- Check if a spell is ready
local function spellReady(spell)
	return not (mq.TLO.Cast.Ready(spell.Name()) == MQ_FALSE)
end


-- Cast a spell on a target, checks mana, buffstatus of target, and if cast is ready
local function castSpell(spell, targ)
	-- Check for nils
	if not spell then
		printf("Spellcast Failed: Nil spell recieved")
		return
	elseif not targ then
		printf("Spellcast Failed: Nil target recieved")
		return
	end

	printf("Casting %s on %s:", spell.Name(), targ.Name())
	-- Check if has buff
	if hasBuff(spell, targ) then
		printf(" - Already has buff %s", spell.Name())
	-- Check if spell is on cooldown
	elseif not spellReady(spell) then
		print(" - Spell not ready")
	-- Check if enough mana
	elseif (spell.Mana() > mq.TLO.Me.CurrentMana() + 2) then
		printf(" - Insufficient mana (%d / %d)", mq.TLO.Me.CurrentMana(), spell.Mana())
	-- Check if can target
	elseif not target(targ) then
		printf(" - No target found")
	-- Cast spell
	else
		mq.cmdf("/cast \"%s\"", spell.Name())
		-- If successful, delay until spell has finished casting
		local result = mq.TLO.Cast.Result()
		if result == "CAST_SUCCESS" then
			mq.delay(spell.MyCastTime.Raw())
			printf(" - Finished cast")
		-- If fizzled, delay and retry
		elseif result == "CAST_FIZZLE" then
			printf(" - Fizzled, retrying...")
			mq.delay(spell.FizzleTime.Raw())
			castSpell(spell, targ)
		-- Otherwise, it's some weird result that probably doesn't matter idk
		else
			printf(" - Unexpected result: %s", result)
		end
	end
end

-- Calculate distance between two spawns
local function distance(from, to)
	local dx = from.X() - to.X()
	local dy = from.X() - to.X()
	return math.sqrt(dx*dx + dy*dy)
end

-- Iterate throuh all extended targets
local function iterateXTargets()
	local cnt = mq.TLO.Me.XTarget()
	if cnt < 1 then
		print("No hostiles")
		return
	end

	local hostiles = {}
	printf("%d Hostiles:", cnt)
	for i=1, cnt do
		local targ = mq.TLO.Spawn(mq.TLO.Me.XTarget(i).ID())
		-- If the target is a valid target
		if targ.Name() then
			local dist = distance(tank, targ)
			hostiles[i] = targ
		else
			-- Invalid target found, uh oh
			print(" - Invalid target at index %d", i)
		end
	end

	-- Sort hostiles by distance (closest to tank first)
	table.sort(hostiles, 
		function(a, b) 
			return distance(a, tank) < distance(b, tank)
		end
	)

	-- Perform checks for all hostiles, starting with those closest to the tank
	for index, hostile in ipairs(hostiles) do
		printf(" - Dist = %f ||  %s", distance(hostile, tank), hostile.Name())
		-- Cast debuff
		if mq.TLO.Me.PctMana() > DEBUFF_MANA_TH then
			castSpell(debuff_spell, hostile)
		end
		-- Cast attack
		if mq.TLO.Me.PctMana() > ATK_MANA_TH then
			castSpell(attack_spell, hostile)
		end
	end

end

-- Heall tank, self, and other group members
local function healAll()
	-- Heal tank
	if (tank and tank.PctHPs() < TANK_HEAL_TH) then
		castSpell(heal_spell, tank)
	end

	-- Heal self
	if (mq.TLO.Me.PctHPs() < SELF_HEAL_TH) then
		castSpell(heal_spell, me_spawn)
	end
	
	-- Iterate through group members, checking their classes
	for i = 0, mq.TLO.Group() do
		local member = mq.TLO.Group.Member(i)
		if not (member.Name() == me_spawn.Name()
				or member.Name() == tank.Name()) then
			-- For all members that are not the tank or yourself
			if member.PctHPs() < OTHER_HEAL_TH then
				castSpell(heal_spell, member)
			end
		end
	end
end

-- Operations for when the tank is in combat
local function inCombatOps()
	print("In combat")
	
	healAll()

	iterateXTargets()
end

-- Temporary combat check function
local function isInCombat()
	-- if mq.TLO.Me.TargetOfTarget.Name() then
	-- 	return false
	-- else
	-- 	return false --false
	-- end
	return mq.TLO.Me.XTarget() > 0
end

-- Regen the healer's mana
local function regenMana()
	while (mq.TLO.Me.PctMana() < 99) and not isInCombat() do
		if not mq.TLO.Me.Sitting() then mq.cmd("/sit") end
		printf("Sitting for mana (%d / %d)", mq.TLO.Me.CurrentMana(), mq.TLO.Me.MaxMana())
		mq.delay(1800)
	end
	mq.cmd("/stand")
end

-- Operatiosn for when the tank is out of combat
local function outCombatOps()
	printf("Out of combat")
	castSpell(buff_spell_1, tank)
	castSpell(buff_spell_2, tank)
	if mq.TLO.Me.PctMana() < 95 then
		regenMana()
	end
end

-- Navigation stuff (might not be used here?)
local function nav()
	print("NAVIGATE")
end

--- MAIN CODE ---

findTank()
if not tank then runscript = false end

while runscript do
	mq.cmd("/stand")
	target(tank)
	if (isInCombat()) then
		inCombatOps()
	else
		outCombatOps()
	end

	-- nav()
	mq.delay(1500)
end

-- Redo combat check (R)
-- Heal entire group (M) (Done)
-- Target nearby enemies (enemies in combat) (M) (Done)
	-- Debuff enemies
	-- MQ Searching
		-- next
		-- npc
		-- xtarhater
-- Navigation (R)

-- Flowchart (M)
-- Video (R)