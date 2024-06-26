local mq = require('mq')
local runscript = true

-- Exit if not a healer
if (not mq.TLO.Me.Class.HealerType()) then
	print("Not a healer, exiting...")
else
	print("You are a healer")
end

local tank = nil
local dps = nil

local TANK_GREATER_HEAL_TH = 65
local TANK_LESSER_HEAL_TH = 80

local SELF_HEAL_TH = 90
local ATK_MANA_TH = 50


-- Get cleric spells
local greater_heal_spell = "Greater Healing"
local lesser_heal_spell = "Healing"
local heal_over_time_spell = "Celestial Remedy"
local caster_buff = "Blessing of Piety"
local debuff_spell = "Holy Might"
local tank_buff1 = "Spirit Armor"
local tank_buff2 = "Daring"
local attack_spell = "Word of Shadow"

-- local heal_spell = mq.TLO.Me.Gem(1)
-- local buff_spell_1 = mq.TLO.Me.Gem(2)
-- local buff_spell_2 = mq.TLO.Me.Gem(3)
-- local attack_spell = mq.TLO.Me.Gem(4)

-- printf("Healing spell: %s", heal_spell.Name())
-- printf("Buff spell 1: %s", buff_spell_1.Name())
-- printf("Buff spell 2: %s", buff_spell_2.Name())
-- printf("Attack spell: %s", attack_spell.Name())


local function target(targ)
	if targ then
		mq.cmdf("/target \"%s\"", targ.Name())
	else
		print("Untargeting")
		mq.cmd("/target")
	end
end

local function findMembers()
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
		elseif class == "NEC" then
			printf(" %s is a dps (%s)", member.Name(), class)
			dps = member
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


-- Might be a way to check if a spell is ready to cast and wait until it is
-- local function castSpell(spell, target)
-- 	-- Check if has buff
-- 	if (target.Buff(spell.Name()).ID()) then
-- 		printf("  Has buff %s", spell.Name())
-- 	else
-- 		printf("  Missing buff %s", spell.Name())
-- 		-- Check mana and cooldown
-- 		if (not mq.TLO.Cast.Ready()) then
-- 			print("  Spell not ready")
-- 		elseif (spell.Mana() > mq.TLO.Me.CurrentMana() + 2) then
-- 			printf("  Insufficient mana (%d / %d)", mq.TLO.Me.CurrentMana(), spell.Mana())
-- 		-- Cast
-- 		else
-- 			mq.cmdf("/cast \"%s\"", spell.Name())
-- 		end
-- 	end
-- end

local function healAll()
	-- Heal tank
	target(tank)
	if (mq.TLO.Target.PctHPs() < TANK_LESSER_HEAL_TH) then
		castSpell(lesser_heal_spell, tank)
	elseif (mq.TLO.Target.PctHPs() < TANK_LESSER_HEAL_TH) then
		castSpell(greater_heal_spell, tank)
	end

	target(dps)
	if (mq.TLO.Target.PctHPs() < TANK_LESSER_HEAL_TH) then
		castSpell(lesser_heal_spell, tank)
	elseif (mq.TLO.Target.PctHPs() < TANK_LESSER_HEAL_TH) then
		castSpell(greater_heal_spell, tank)
	end

	-- Heal self
	if (mq.TLO.Me.PctHPs() < SELF_HEAL_TH) then
		castSpell(lesser_heal_spell, mq.TLO.Me())
	end

	target(tank)
end

local function buffTank()
	local tankbuffs = {tank_buff1, tank_buff2}
	target(tank)
	-- for i, buff in ipairs(tankbuffs) do
		if(mq.TLO.Target.Buff(tank_buff1).ID()) then
			print("already has ", tank_buff1)
		else
			mq.cmdf('/cast "%s"', tank_buff1)
			print("casting ", tank_buff1)
		end

		if(mq.TLO.Target.Buff(tank_buff2).ID()) then
			print("already has ", tank_buff2)
		else
			mq.cmdf('/cast "%s"', tank_buff2)
			print("casting ", tank_buff2)
		end


	-- end
end

local function buffdps()
	target(dps)
	if(mq.TLO.Target.Buff(caster_buff).ID()) then
		print("Dps has buff")
	else
		mq.cmdf('/cast "%s"', caster_buff)
		print("casting ", caster_buff)
	end

	mq.cmd('/target clear')
	if(mq.TLO.Me.Buff(caster_buff).ID()) then
		print("I already have ", caster_buff)
	else
		mq.cmdf('/cast "%s"', caster_buff)
		print("casting ", caster_buff)
	end
end

local function debuffEnemies()
	print("  DEBUFFS")
end

local function attackEnemies()
	print("  ATTACK")
end

local function combatBuffs()
	print("combat buffs")
end

local function inCombatOps()
	print("In combat")
	healAll()

	combatBuffs()

	debuffEnemies()

	attackEnemies()
end

local function checkMana()
	print("checking mana")
	local MANA_TH = 50
	if(mq.TLO.Me.PctMana() < 50) then
		print("low mana")
		local tankstartingHPs = mq.TLO.Target.PctHPs()
		while (mq.TLO.Me.PctMana() < 100) do
			if(mq.TLO.Me.CombatState() == "COMBAT" or mq.TLO.Target.PctHPs() < tankstartingHPs) then
				print("sitting interuppted")
				mq.cmd('/stand')
				break
			end
			if (not mq.TLO.Me.Sitting()) then
				print("sitting")
				mq.cmd('/sit')
			end
		end
	end
end

local function outCombatOps()
	printf("Out of combat")

	checkMana()

	buffTank()

	buffdps()
end


local function nav()
	print("NAVIGATE")
end


local function isInCombat()
	if mq.TLO.Me.TargetOfTarget.Name() or (mq.TLO.Me.CombatState == "COMBAT") then
		return true
	else
		return false
	end
end


findMembers()

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