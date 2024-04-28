package.path = package.path .. ";/home/eqemu/server/quests/?.lua";
require("Blackjack");
require("GoFish");

local npc;
local client;


function BlackjackInstance:customDealerAI()
	self._dealer.hand = Deck.new(0,0);

	self._dealer.hand:addTop(self.deck:drawRandom());
	self._dealer.hand:addTop(self.deck:drawRandom());
	self._dealer.hand:addTop(self.deck:drawRandom());
	self._dealer.char:Say("Fuck you I get 3 cards");
end

local game;


function event_say(e)
	npc = e.self;
	client = e.other;

	if (string.sub(e.message, 1, 1) == "m") then
		local amount = tonumber(string.sub(e.message, 2)) or 0;
		if (game) then
			game:handin(amount);
			game:go(nil, client);
		end
		return;
	end

	if (game) then
		game:go(e.message, client)
	else
		game = BlackjackInstance.new(npc, client, 10);
		if (game) then
			game:go(nil, client);
		end
	end
end


function event_trade(e)
	local trade = e.trade;
	npc = e.self;
	client = e.other;

	local money = trade.copper + 10*(trade.silver + 10*(trade.gold + 10*(trade.platinum)));
	if (money) then
		if (game) then
			game:handin(money);
			game:go();
		else
			client:AddMoneyToPP(trade.copper, trade.silver, trade.gold, trade.platinum, true);
		end
	end
end