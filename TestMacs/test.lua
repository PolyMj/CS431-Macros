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


while runscript do
	printf("Test")
	mq.cmd('/sit')
	mq.delay(1000)
end