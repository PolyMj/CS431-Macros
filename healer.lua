local mq = require('mq')
local runscript = true

-- Exit if not a healer
if (not mq.TLO.Me.Class.HealerType()) then
	print("Not a healer, exiting...")
else
	print("You are a healer")
end

local tank = nil

local TANK_HEAL_TH = 80
local SELF_HEAL_TH = 90
local ATK_MANA_TH = 50


-- Get spells
local heal_spell = mq.TLO.Me.Gem(1)
local buff_spell_1 = mq.TLO.Me.Gem(2)
local buff_spell_2 = mq.TLO.Me.Gem(3)
local attack_spell = mq.TLO.Me.Gem(4)

printf("Healing spell: %s", heal_spell.Name())
printf("Buff spell 1: %s", buff_spell_1.Name())
printf("Buff spell 2: %s", buff_spell_2.Name())
printf("Attack spell: %s", attack_spell.Name())


local function target(targ)
	if targ then
		mq.cmdf("/target \"%s\"", targ.Name())
	else
		print("Untargeting")
		mq.cmd("/target")
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


-- Might be a way to check if a spell is ready to cast and wait until it is
local function castSpell(spell, target)
	-- Check if has buff
	if (target.Buff(spell.Name()).ID()) then
		printf("  Has buff %s", spell.Name())
	else
		printf("  Missing buff %s", spell.Name())
		-- Check mana and cooldown
		if (not mq.TLO.Cast.Ready()) then
			print("  Spell not ready")
		elseif (spell.Mana() > mq.TLO.Me.CurrentMana() + 2) then
			printf("  Insufficient mana (%d / %d)", mq.TLO.Me.CurrentMana(), spell.Mana())
		-- Cast
		else
			mq.cmdf("/cast \"%s\"", spell.Name())
		end
	end
end

local function healAll()
	-- Heal tank
	if (mq.TLO.Target.PctHPs() < TANK_HEAL_TH) then
		castSpell(heal_spell, tank)
	end

	-- Heal self
	if (mq.TLO.Me.PctHPs() < SELF_HEAL_TH) then
		castSpell(heal_spell, mq.TLO.Me())
	end

end

local function buffTank()
	print("  BUFFS")
end

local function debuffEnemies()
	print("  DEBUFFS")
end

local function attackEnemies()
	print("  ATTACK")
end


local function inCombatOps()
	print("In combat")
	healAll()

	buffTank()

	debuffEnemies()

	attackEnemies()
end


local function outCombatOps()
	printf("Out of combat")
end


local function nav()
	print("NAVIGATE")
end


local function isInCombat()
	if mq.TLO.Me.TargetOfTarget.Name() then
		return true
	else
		return false
	end
end


findTank()

while runscript do
	target(tank)
	if (isInCombat()) then
		inCombatOps()
	else
		outCombatOps()
	end

	nav()
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