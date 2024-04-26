function event_say(e)
	if (e.message:findi("Hail")) then
		e.self:Say("Hey there, you hear about the [Riptide Brothers]?");
	end

	if (e.message == "Riptide Brothers") then
		e.self:Say("They're a pair of street bookies that you'll find 'round here. They got me good, had to give up my preciouse blade just to repay my debt.");
		e.self:Say("I'm nothing without it, but I can't even pay them enough to try to win it back.");
		e.self:Say("You wouldn't be willing to [help me], would you?");
	end
	if (e.message == "help me") then
		e.self:Say("Hail the night! I wish you the best of luck, it won't be easy. ");
	end
end



function event_trade(e)
	local qglobals = eq.get_qglobals(e.other);
	if(qglobals["Nesir's_Zweihandler"] ~= nil or qglobals) then
		e.self:Say("By the veil of night! Is that my Zweizwei? Thank the gods!");
		e.self:Say("Here, it's not much, but I was saving up to challege him again, its only right that you have it. ");
		e.other:AddPlatinum(186, true);
		e.self:Say("Also, here's the sword I was using in the meantime. It's not enough to repay you but I hope you'll accept it regardless. ");
		e.other:SummonItem(122674); -- Random got-tier sword
	end
end