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
	if (#self.cards == 2) then
		if (self.cards[1]:isAce()) then
			return ((self.cards[2]:value()) == 10);
		elseif (self.cards[2]:isAce()) then
			return (self.cards[1]:value() == 10);
		end
	end
	return false;
end

function Deck:toStringVal()
	return "Value of " .. self:optimalValue() .. " - " .. self:toString();
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
function BlackjackInstance.new(npc, client, required_payment)
	self = setmetatable({}, BlackjackInstance);
	
	-- Return nil if invalid client or npc
	if (not client or not npc) then
		return nil;
	end

	self.required_payment = required_payment or 0;

	self.requesting_payment = false;

	self.deck = nil;

	self._player = {
		char = client;
		handin = 0; -- Amount the player has payed, set to zero once recieved
		due = 0; -- Amount the player is owed (from winnings)
		hands = {};
		bets = {};
		splitAce = false;
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
		optionsPrompt = "";
		options = {};
		buttons = {};
		errorDialogue = {};
	};

	self.RETURNS = {
		LOSE = 0;
		DRAW = 1;
		WIN = 2;
		BLACKJACK = 3;
	};

	self._hand_selection = 0;

	self.dealerAI = BlackjackInstance.defaultDealerAI;

	self._STAGE = BlackjackInstance._initializeGame;

	return self;
end

-- Adds amount_copper to the player's handin total
function BlackjackInstance:handin(amount_copper)
	if (amount_copper > 0) then
		self._player.handin = self._player.handin + (amount_copper or 0);
	end
end

-- Forces the player to pay against their will
function BlackjackInstance:forceHandin(amount_copper)
	if (amount_copper > 0) then
		if (self._player.char:TakeMoneyFromPP(amount_copper, true)) then
			self._player.handin = self._player.handin + (amount_copper or 0);
		end
	end
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
	table.insert(self._player.bets, (bet or 0));
end

-- Main function run from quest NPCs
function BlackjackInstance:go(text)
	self:_STAGE(text);
end


function BlackjackInstance:_initializeGame()
	if (self._player.handin < self.required_payment) then
		self._dealer.char:Say(
			"You'll need to pay before you play (" .. 
			self._player.handin .. "/" .. self.required_payment .. ")"
		);
		self.requesting_payment = true;
		return;
	end
	self.requesting_payment = false;

	self.deck = Deck.new(1,0);
	self:getDealerHand();

	-- Draw two random cards for the player
	local player_hand = Deck.new(0,0);
	player_hand:addTop(self.deck:drawRandom());
	player_hand:addTop(self.deck:drawRandom());
	self:addPlayerHand(player_hand, self._player.handin);
	self._player.handin = 0;
	self:_status();
end


function BlackjackInstance:gamestateString()

end


function BlackjackInstance:displayGame()
	local dia_string = "{title: Blackjack with " .. self._dealer.char:GetName() .. "} ";
	
	-- Buttons
	if (#self._outText.buttons > 0) then
		dia_string = dia_string .. "{button_one: " .. self._outText.buttons[1] .. "} ";
	end
	if (#self._outText.buttons > 1) then
		dia_string = dia_string .. "{button_two: " .. self._outText.buttons[2] .. "} ";
	end
	self._outText.buttons = {};

	-- Window type
	dia_string = dia_string .. "wintype:1 ";

	-- Dealer's hand
	dia_string = dia_string .. "{linebreak} {y} Dealer's hand: {bullet}" .. self._dealer:toStringHidden() .. "~ ";
	
	-- Active hands
	if (#self._player.hands > 0) then
		dia_string = dia_string .. "{linebreak} {lb} Player's hands: ";

		for i,hand in pairs(self._player.hands) do
			dia_string = dia_string .. "{bullet} " .. hand:toStringVal() .. " ";
			dia_string = dia_string .. " with bet of " .. self._player.bets[i] .. "c ";
		end
		dia_string = dia_string .. "~ ";
	end

	-- Finished hands
	if (#self._outText.finishedHands > 0) then
		dia_string = dia_string .. "{linebreak} {gray} Finished's hands: ";

		for i,fh in pairs(self._outText.finishedHands) do
			dia_string = dia_string .. "{bullet} " .. fh .. " ";
		end
		dia_string = dia_string .. "~ ";
	end
	self._outText.finishedHands = {};

	-- Diaplay bet
	local totalBet = 0;
	for i,bet in pairs(self._player.bets) do
		totalBet = totalBet + bet;
	end
	if (totalBet > 0) then
		dia_string = dia_string .. "{linebreak} {gold} Total bet = " .. totalBet .. "~ ";
	end

	if (#self._player.hands < 0) then
		dia_string = dia_string .. "{linebreak} {r} GAME OVER";
	else
		if (#self._outText.errorDialogue > 0) then
			dia_string = dia_string .. "{linebreak} {r}"
			for i,s in pairs(self._outText.errorDialogue) do
				dia_string = dia_string .. "{bullet} " .. s .. " ";
			end
			dia_string = dia_string .. "~ ";
		end
		self._outText.errorDialogue = {};
	end

	self._player.char:DialogueWindow(dia_string);

	-- Options are said in main chat
	if (#self._outText.options > 0) then	
		options_string = (self._outText.optionsPrompt or "OPTIONS:");
		for i,v in pairs(self._outText.options) do
			options_string = options_string .. " [" .. v .. "]"
		end
		self._dealer.char:Say(options_string);
	end
	self._outText.options = {};
end


function BlackjackInstance:_status()
	for i,hand in pairs(self._player.hands) do
		local value = hand:optimalValue();
		if (hand:isBlackjack()) then
			self:_finishHand(i, self.RETURNS.BLACKJACK, "Blackjack!");
		elseif (value > 21) then
			self:_finishHand(i, self.RETURNS.LOSE, "Busted!");
		end
	end

	if (#self._player.hands > 0) then
		self:_turn();
	else
		self:displayGame();
		self:Cashout();
		self._STAGE = BlackjackInstance._initializeGame;
	end
end


-- Start a player's turn, prompting them to select their move
function BlackjackInstance:_turn()

	local canHit = true;
	if (self._player.splitAce) then
		canHit = false;
		for i,hand in pairs(self._player.hands) do
			if (not hand.cards[1]:isAce()) then
				canHit = true;
				break;
			end
		end
	end

	local canSplit = false;
	for i,hand in pairs(self._player.hands) do
		if (hand:count() > 1) then
			canSplit = true;
			break;
		end
	end


	if (canHit) then 
		table.insert(self._outText.options, "Hit");
	end

	if (canSplit) then 
		table.insert(self._outText.options, "Split");
	end

	table.insert(self._outText.options, "Stand");
	table.insert(self._outText.options, "Stand All");

	self._STAGE = BlackjackInstance._parseTurn;
	self:displayGame()
end


function BlackjackInstance:_parseTurn(text)
	if (not text) then
		self:_turn();
		return;
	end

	if (text == "Split") then
		self:_split();
	elseif (text == "Hit") then
		self:_hit();
	elseif (text == "Stand") then
		self:_stand();
	elseif (text == "Stand All") then
		for index,hand in pairs(self._player.hands) do
			self:_checkStand(index);
		end
		self:displayGame();
	else
		table.insert(self._outText.errorDialogue, "Sorry, not sure what you want to do.");
		self:_turn();
		return;
	end
end


function BlackjackInstance:_split(text)
	if (text and text == "Back") then
		self:_turn();
		return;
	end

	local hand_index = tonumber(text or "0");

	if (hand_index <= 0 or hand_index > #self._player.hands) then
		self._outText.optionsPrompt = "Select a hand to split:";
		
		for i,hand in pairs(self._player.hands) do
			if (hand:count() > 1) then
				table.insert(self._outText.options, i);
			end
		end

		table.insert(self._outText.buttons, "Back");
		self:displayGame();
		self._STAGE = BlackjackInstance._split;
		return;
	end

	self._hand_selection = hand_index
	self:_buySplit();
end


function BlackjackInstance:_buySplit(text)
	local hand = self._player.hands[self._hand_selection];
	local bet = self._player.bets[self._hand_selection]

	if (text and text == "Back") then
		self:_status();
		return;
	end

	if (self._player.handin < bet) then
		table.insert(self._outText.errorDialogue, "You're gonna need to pay at least " .. bet .. " to split that hand (" .. self._player.handin .. "/" .. bet .. ")")
		self.requesting_payment = true;
		self._STAGE = BlackjackInstance._buySplit;
		self:displayGame();
		return;
	end

	self.requesting_payment = false;
	
	if (self._player.hands[self._hand_selection]:count() > 1) then
		local card = self._player.hands[self._hand_selection]:drawTop();
		local new_hand = Deck.new(0,0);
		new_hand:addTop(card);
		self:addPlayerHand(new_hand, self._player.handin);
		self._player.handin = 0;
	else
		self:_split();
		self:Cashout();
		return;
	end
	self:_status();
end



function BlackjackInstance:_hit(text)
	if (text and text == "Back") then
		self:_turn();
		return;
	end

	local hand_index = tonumber(text) or 0;

	if (hand_index <= 0 or hand_index > #self._player.hands) then
		self._outText.optionsPrompt = "Select a hand to hit:";
		if (self._player.splitAce) then
			for i,hand in pairs(self._player.hands) do
				if (not hand.cards[1]:isAce()) then
					table.insert(self._outText.options, i);
				end
			end
		else
			for i,hand in pairs(self._player.hands) do
				table.insert(self._outText.options, i);
			end
		end

		table.insert(self._outText.buttons, "Back");
		self._STAGE = BlackjackInstance._hit;
		self:displayGame();
		return;
	end

	if (self.splitAce) then
		local hand = self._player.hands[hand_index];
		if (hand.cards[1]:isAce()) then
			self:_hit();
			return;
		end
	end
	self._player.hands[hand_index]:addTop(self.deck:drawRandom());
	self:_status();
end

function BlackjackInstance:_stand(text)
	if (text and text == "Back") then
		self:_turn();
		return;
	end

	local hand_index = tonumber(text) or 0;

	if (hand_index <= 0 or hand_index > #self._player.hands) then
		self._outText.optionsPrompt = "Select a hand to stand:";
		for i,hand in pairs(self._player.hands) do
			table.insert(self._outText.options, i);
		end
		table.insert(self._outText.buttons, "Back");
		self._STAGE = BlackjackInstance._stand;
		self:displayGame();
		return;
	end

	self:_checkStand(hand_index);
	self:_status()
end

 -- Check the result of a stand with the given hand
function BlackjackInstance:_checkStand(hand_index)
	local hand = self._player.hands[hand_index];

	if (hand:isBlackjack()) then
		if (self._dealer.hand:isBlackjack()) then
			self:_finishHand(hand_index, self.RETURNS.DRAW, "Tied with Blackjack!");
		else
			self:_finishHand(hand_index, self.RETURNS.BLACKJACK, "Won with Blackjack!");
		end
	elseif (hand:optimalValue() == self._dealer.hand:optimalValue()) then
		self:_finishHand(hand_index, self.RETURNS.DRAW, "Tied with the dealer");
	elseif (hand:optimalValue() < self._dealer.hand:optimalValue()) then
		self:_finishHand(hand_index, self.RETURNS.LOSE, "Lost to the dealer");
	else
		self:_finishHand(hand_index, self.RETURNS.WIN, "Beat the dealer!");
	end
end


function BlackjackInstance:_finishHand(index, return_factor, message)
	if (index > 0 and index <= #self._player.hands) then
		-- Pay back player return_facotor * their bet
		self._player.due = self._player.due + math.floor(self._player.bets[index] * return_factor);

		-- Add the hand to the outText to be displayed later
		table.insert(
			self._outText.finishedHands, 
			(message or "finished") .. " - " .. self._player.hands[index]:toStringVal()
		);

		-- Remove hand and bet
		table.remove(self._player.bets, index);
		table.remove(self._player.hands, index);
	end
end

-- Returns all due money to the player, both from winnings and remaining handin (if any)
function BlackjackInstance:Cashout()
	payClient(self._player.char, self._player.handin + self._player.due);
end