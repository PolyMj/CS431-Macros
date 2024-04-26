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


function event_say(e)
	npc = e.self;
	client = e.other;

	if (e.message:findi("Hail")) then
		local game = BlackjackInstance.new(npc, client);
		if (game) then
			npc:Say(game.player.char:AccountName());
			game.getDealerHand = BlackjackInstance.customDealerAI;

			game:initializeGame()
	
			npc:Say(game.dealer.hand:toString());
		end
	end


	npc:Say("Test");

end