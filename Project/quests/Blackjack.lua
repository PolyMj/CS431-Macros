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

		toStringHidden = function(self)
			if (self.hand:count() < 1) then
				return "EMPTY";
			end
		
			local str = "{: " .. self.hand.cards[1]:toString();
			for i=2, self.hand:count() do
				str = str .. " : " .. Card.faceDownCard();
			end
		
			return str .. " :}";
		end
	};

	self._outText = {
		finishedHands = {};
		activeHands = {};
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
	self._dealer.hand = Deck.new(0,0);

	self._dealer.hand:addTop(self.deck:drawRandom());
	self._dealer.hand:addTop(self.deck:drawRandom());
end

function BlackjackInstance:getDealerHand()
	self:dealerAI();

	if (self._dealer.hand:optimalValue() > 21 or self._dealer.hand:count() < 2) then
		self:defaultDealerAI();
	end
end

function BlackjackInstance:addPlayerHand(hand, bet)
	table.insert(self._player.hands, hand);
	table.insert(self._player.bets, bet);
end

function BlackjackInstance:go(text)
	self:_STAGE(text);

	self:_status();
end


function BlackjackInstance:_initializeGame()
	self.deck = Deck.new(1,0);
	self:getDealerHand();

	-- Draw two random cards for the player
	local player_hand = Deck.new(0,0);
	player_hand:addTop(self.deck:drawRandom());
	player_hand:addTop(self.deck:drawRandom());
	self:addPlayerHand(player_hand, 0);
end


function BlackjackInstance:displayGame()
	local str = "FINISHED HANDS: ";
	for i,v in pairs(self._outText.finishedHands) do
		str = str .. v;
	end

	str = str .. " # ACTIVE HANDS: ";
	for i,v in pairs(self._outText.activeHands) do
		str = str .. v;
	end

	str = str .. " # DEALER'S HAND: " .. self._dealer:toStringHidden();

	self._dealer.char:Say(str);
end


function BlackjackInstance:_status()
	for i,hand in pairs(self._player.hands) do
		local value = hand:optimalValue();
		if (hand:isBlackjack()) then
			self:_finnishHand(i, self.RETURNS.BLACKJACK, "Blackjack!");
		elseif (value > 21) then
			self:_finnishHand(i, self.RETURNS.LOSE, "Busted!");
		else
			table.insert(self._outText.activeHands, hand:toStringVal());
		end
	end

	self:displayGame();
	self._STAGE = BlackjackInstance._status;
end



function BlackjackInstance:_finnishHand(index, return_factor, message)
	if (index > 0 and index <= #self._player.hands) then
		-- Pay back player return_facotor * their bet
		self._player.due = math.floor(self._player.due + self._player.bets[index] * return_factor);

		-- Add the hand to the outText to be displayed later
		table.insert(
			self._outText.finishedHands, 
			(message or "Finnished") .. " - " .. self._player.hands[index]:toStringVal()
		);

		-- Remove hand and bet
		table.remove(self._player.bets, index);
		table.remove(self._player.hands, index);
	end
end

-- Returns all due money to the player, both from winnings and remaining handin (if any)
function BlackjackInstance:Cashout()
	payClient(self._player.handin + self._player.due);
end