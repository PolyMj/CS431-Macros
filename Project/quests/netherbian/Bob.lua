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

	if (game) then
		game:go(e.message)
	else
		game = BlackjackInstance.new(npc, client);
		if (game) then
			game:go();
		end
	end

end