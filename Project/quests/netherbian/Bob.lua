package.path = package.path .. ";/home/eqemu/server/quests/?.lua";
require("Blackjack");

local npc;
local client;


function BlackjackInstance:customDealerAI()
	self.dealer.hand = Deck.new(0,0);

	self.dealer.hand:addTop(self.deck:drawRandom());
	self.dealer.hand:addTop(self.deck:drawRandom());
	self.dealer.hand:addTop(self.deck:drawRandom());
	self.dealer.char:Say("Fuck you I get 3 cards");
end

local game;


function event_say(e)
	npc = e.self;
	client = e.other;

	if (string.sub(e.message, 1, 1) == "m") then
		local amount = tonumber(string.sub(e.message, 2)) or 0;
		if (game) then
			game:handin(amount);
			game:go();
		end
		return;
	end

	if (game) then
		game:go(e.message)
	else
		game = BlackjackInstance.new(npc, client, 10);
		if (game) then
			game:go();
		end
	end

end