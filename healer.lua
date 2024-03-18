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
local ATK_MANA_TH = 60
local DEBUFF_MANA_TH = 40


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

local SPELL_NOT_READY = mq.TLO.Cast.Ready("NOT A SPELL")


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

	-- Assign tank, or exit from macro if no tank was found
	if (tank) then
		printf("Chosen tank is %s (%s)", tank.Name(), tank.Class.ShortName())
	else
		print("No tank was found, ending macro...")
		runscript = false
	end
end

local function hasBuff(spell, targ)
	local val = targ.Buff(spell.Name()).ID()
	return val
end


local function spellReady(spell)
	return not (mq.TLO.Cast.Ready(spell.Name()) == SPELL_NOT_READY)
end


-- Cast a spell on a target, checks mana, buffstatus of target, and if cast is ready
local function castSpell(spell, targ)
	if not spell then
		printf("Nil spell recieved")
		return
	elseif not targ then
		printf("Nil target recieved")
		return
	end

	printf("Casting %s on %s:", spell.Name(), targ.Name())
	-- Check if has buff
	if hasBuff(spell, targ) then
		printf(" - Already has buff %s", spell.Name())
	else
		-- Check if spell is on cooldown
		if not spellReady(spell) then
			print(" - Spell not ready")
		-- Check if enough mana
		elseif (spell.Mana() > mq.TLO.Me.CurrentMana() + 2) then
			printf(" - Insufficient mana (%d / %d)", mq.TLO.Me.CurrentMana(), spell.Mana())
		-- Target and cast
		elseif target(targ) then
			mq.cmdf("/cast \"%s\"", spell.Name())
		end
	end
end

local function distance(from, to)
	local dx = from.X() - to.X()
	local dy = from.X() - to.X()
	return math.sqrt(dx*dx + dy*dy)
end


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
			print(i)
		end
	end

	-- Sort hostiles by distance
	table.sort(hostiles, 
		function(a, b) 
			return distance(a, tank) < distance(b, tank)
		end
	)

	for index, hostile in ipairs(hostiles) do
		printf(" - Dist = %d ||  %s", index, distance(hostile, tank), hostile.Name())
		if mq.TLO.Me.PctMana() > DEBUFF_MANA_TH then
			castSpell(debuff_spell, hostile)
		end
		mq.delay(10)
	end

end


local function healAll()
	-- Heal tank
	if (tank and tank.PctHPs() < TANK_HEAL_TH) then
		castSpell(heal_spell, tank)
	end

	-- Heal self
	if (mq.TLO.Me.PctHPs() < SELF_HEAL_TH) then
		castSpell(heal_spell, me_spawn)
	end

end


local function inCombatOps()
	print("In combat")
	healAll()

	iterateXTargets()
end


local function outCombatOps()
	printf("Out of combat")
	castSpell(buff_spell_1, tank)
	castSpell(buff_spell_2, tank)
end


local function nav()
	print("NAVIGATE")
end


local function isInCombat()
	if mq.TLO.Me.TargetOfTarget.Name() then
		return true
	else
		return true --false
	end
end

--- MAIN CODE ---

findTank()

while runscript do
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
-- Heal entire group (M)
-- Target nearby enemies (enemies in combat) (M)
	-- Debuff enemies
	-- MQ Searching
		-- next
		-- npc
		-- xtarhater
-- Navigation (R)

-- Flowchart (M)
-- Video (R)s