package.path = package.path .. ";/home/eqemu/server/quests/?.lua";
require("Cards");

	-- Additions to Cards / Deck classes -- 
--
function Card:value()
	if (self:isAce()) then
		return 1;
	elseif(self:isFace()) then
		return 10;
	elseif(self:isNumber()) then
		return self:rankID();
	else
		print("ERROR: Joker recieved in blackjack");
		return 0;
	end
end


function Deck:minValue()
	local value = 0;
	for i, c in ipairs(self.cards) do
		value = value + c:value();
	end
	return value;
end

function Deck:optimalValue()
	local value = 0;
	local ace_count = 0;
	for i, c in ipairs(self.cards) do
		value = value + c:value();
		if (c:isAce()) then
			ace_count = ace_count + 1;
		end
	end

	while (value <= 11 and ace_count > 0) do
		value = value + 10;
		ace_count = ace_count - 1;
	end
	return value;
end

function Deck:isBlackjack()
	if (self.cards[1]:isAce()) then
		return (self.cards[2]:value() == 10);
	elseif (self.cards[2]:isAce()) then
		return (self.cards[1]:value() == 10);
	else
		return false;
	end
end

function Deck:toStringVal()
	return "Value = " .. self:optimalValue() .. " - " .. self:toString();
end

	-- End Card / Deck additions -- 
--

function payClient(client, amount)
	if (amount > 0) then
		local copp = amount % 10;
		amount = math.floor(amount / 10);
		local silv = amount % 10;
		amount = math.floor(amount / 10);
		local gold = amount % 10;
		amount = math.floor(amount / 10);
		local play = amount % 10;
		
		client:AddMoneyToPP(copp, silv, gold, play, true);
	end

end


	-- BLACKJACKINSTACE -- 
--

BlackjackInstance = {};
BlackjackInstance.__index = BlackjackInstance;
function BlackjackInstance.new(npc, client)
	self = setmetatable({}, BlackjackInstance);
	
	-- Return nil if invalid client or npc
	if (not client or not npc) then
		return nil;
	end

	self.deck = nil;

	self._player = {
		char = client;
		handin = 0; -- Amount the player has payed, set to zero once recieved
		due = 0; -- Amount the player is owed (from winnings)
		hands = {};
		bets = {};
	};

	self._dealer = {
		char = npc;
		hand = nil;
	};

	-- For custom (and preset) dialogue
	self.dialogue = {

	};

	self._outText = {
		finishedHands = {};
		activeHands = {};
		dealerHand = nil;
	};

	self.RETURNS = {
		LOSE = 0;
		DRAW = 1;
		WIN = 2;
		BLACKJACK = 3;
	};

	self.dealerAI = BlackjackInstance.defaultDealerAI;

	self._STAGE = BlackjackInstance._initializeGame;

	return self;
end

function BlackjackInstance.defaultDealerAI(self)
	self.dealer.hand = Deck.new(0,0);

	self.dealer.hand:addTop(self.deck:drawRandom());
	self.dealer.hand:addTop(self.deck:drawRandom());
end

function BlackjackInstance:getDealerHand()
	self:dealerAI();

	if (self.dealer.hand:optimalValue() > 21 or self.dealer.hand:count() < 2) then
		self:defaultDealerAI();
	end
end

function BlackjackInstance:go(text)
	self:_STAGE(text);

	self:_status();
end


function BlackjackInstance:_initializeGame()
	self.deck = Deck.new(1,0);
	self:getDealerHand();

	-- Draw two random cards for the player
	table.insert(self.player.hands, self.deck:drawRandom());
	table.insert(self.player.hands, self.deck:drawRandom());
end


function BlackjackInstance:_status()
	for i,hand in pairs(self.player.hands) do
		local value = hand:optimalValue();
		if (hand:isBlackjack()) then
			self:_finnishHand(i, self.RETURNS.BLACKJACK, "Blackjack!");
		elseif (value > 21) then
			self:_finnishHand(i, self.RETURNS.LOSE, "Busted!");
		else
			table.inset(self.outText.activeHands, hand:toStringVal());
		end
	end
end



function BlackjackInstance:_finnishHand(index, return_factor, message)
	if (index > 0 and index <= #self.player.hands) then
		-- Pay back player return_facotor * their bet
		self.player.due = math.floor(self.player.due + self.player.bets[index] * return_factor);

		-- Add the hand to the outText to be displayed later
		table.insert(
			self._outText.finishedHands, 
			(message or "Finnished") .. " - " .. self.player.hands[index]:toStringVal()
		);

		-- Remove hand and bet
		table.remove(self.player.bets, index);
		table.remove(self.player.hands, index);
	end
end

-- Returns all due money to the player, both from winnings and remaining handin (if any)
function BlackjackInstance:Cashout()
	payClient(self.player.handin + self.player.due);
end