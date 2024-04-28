package.path = package.path .. ";/home/eqemu/server/quests/?.lua";
require("Cards");

BLACKJACK_FLAG = "-BlackJack";
WINNINGS_FLAG = "-BJWinnings";
WAGERS_FLAG = "-BJWagers";

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


function addToBucket(client, FLAG, addend)
	local data = tonumber(client:GetBucket(FLAG));
	local data = data or 0;
	local data = data + addend;
	client:SetBucket(FLAG, tostring(data));
end


	-- BLACKJACKINSTACE -- 
--

BlackjackInstance = {
	STATUS = {
		UNSTARTED = -1;
		ONGOING = 0;
		FINISHED = 1;
	};
};
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
		handsWon = 0;
		handsLost = 0;
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
		errorDialogue = {};
	};

	self.RETURNS = {
		LOSE = 0;
		DRAW = 1;
		WIN = 2;
		BLACKJACK = 3;
	};

	self._hand_selection = 0;

	self.status = false;

	self.dealerAI = BlackjackInstance.defaultDealerAI;

	self._STAGE = BlackjackInstance._initializeGame;

	return self;
end

function BlackjackInstance:getFlagSuffix()
	return self._dealer.char:GetCleanName() .. self._player.char:AccountID();
end

function BlackjackInstance:getWinnings(client)
	client = client or self._player.char
	local data = tonumber(client:GetBucket(WINNINGS_FLAG..self:getFlagSuffix())) or 0;
	return data;
end
function BlackjackInstance:getWagers(client)
	client = client or self._player.char
	local data = tonumber(client:GetBucket(WAGERS_FLAG..self:getFlagSuffix())) or 0;
	return data;
end

-- Adds amount_copper to the player's handin total
function BlackjackInstance:handin(amount_copper, client)
	if (client and self._player.char:AccountID() ~= client:AccountID()) then
		self:exit();
		self:_fromBucket(self._dealer.char, client);
	end

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

-- Removes a number of cards from self.deck and adds them to self._dealer.hand
function BlackjackInstance.defaultDealerAI(self)
	self._dealer.hand:addTop(self.deck:drawRandom());
	self._dealer.hand:addTop(self.deck:drawRandom());
end

function BlackjackInstance:getDealerHand()
	self._dealer.hand = Deck.new(0,0);
	
	self:dealerAI();

	if (self._dealer.hand:optimalValue() > 21 or self._dealer.hand:count() < 1) then
		self.deck:addDeck(self._dealer.hand);
		self._dealer.hand:clear();
		self:defaultDealerAI();
	end
end

function BlackjackInstance:addPlayerHand(hand, bet)
	table.insert(self._player.hands, hand);
	table.insert(self._player.bets, (bet or 0));

	if (bet) then
		addToBucket(
			self._player.char, 
			WAGERS_FLAG .. self:getFlagSuffix(),
			bet
		);
	end
end

-- Main function run from quest NPCs
function BlackjackInstance:go(text, client)
	-- Checks if passed in client matches current. If not, save other game and create new game
	if (client and self._player.char:AccountID() ~= client:AccountID()) then
		self:exit();
		self:_fromBucket(self._dealer.char, client);
		return;
	end

	if (text and text == "Forfeit") then
		self._STAGE = BlackjackInstance._initializeGame;
		self:_deleteBucket();
		self.status = BlackjackInstance.STATUS.FINISHED;
		return;
	end

	if (text and text == "Exit") then
		-- Only save game if there is actually a game in progress
		if (#self._player.hands > 0) then
			self._dealer.char:Say("Game saved");
			self:exit();
		end
		return;
	end
	self:_STAGE(text);
end

function BlackjackInstance:exit()
	if (self.status ~= BlackjackInstance.STATUS.ONGOING) then
		return;
	end
	self:Cashout();
	local FLAG = BLACKJACK_FLAG .. self:getFlagSuffix();

	local data = "";

	data = data .. self._dealer.hand:to64() .. " ";

	data = data .. self.deck:to64() .. " ";

	data = data .. self._player.handsWon .. " ";
	data = data .. self._player.handsLost;

	for i,hand in pairs(self._player.hands) do
		data = data .. " " .. hand:to64();
		data = data .. "_" .. self._player.bets[i];
	end

	self._player.char:SetBucket(FLAG, data);
	self._STAGE = BlackjackInstance._initializeGame;
	self.status = BlackjackInstance.STATUS.UNSTARTED;
end

function BlackjackInstance:_deleteBucket()
	local FLAG = BLACKJACK_FLAG .. self:getFlagSuffix();
	self:Cashout();
	self._player.char:DeleteBucket(FLAG);
end

function BlackjackInstance:_fromBucket(npc, client)
	local FLAG = BLACKJACK_FLAG .. npc:GetCleanName() .. client:AccountID();
	local data = client:GetBucket(FLAG);
	
	-- Set new client
	self._player.char = client;

	-- If data bucket load was successful, play
	if (self:_parseBucket(data)) then
		self._STAGE = BlackjackInstance._turn;
		self.status = BlackjackInstance.STATUS.ONGOING;
	-- Otherwise, new game
	else
		self._dealer.char:Say("No game data found, creating new game...");
		self._STAGE = BlackjackInstance._initializeGame;
		self.status = BlackjackInstance.STATUS.UNSTARTED
	end

	client:DeleteBucket(FLAG);
end

function BlackjackInstance:_parseBucket(data)
	if (#data < 1) then return false end

	local chunks = {};

	-- Separated by whitespace
	for chunk in data:gmatch("%S+") do
		table.insert(chunks, chunk);
	end
	if (#chunks < 3) then return false end

	self._dealer.hand = Deck.from64(chunks[1]);
	self.deck = Deck.from64(chunks[2]);

	self._player.handsWon = tonumber(chunks[3]);
	self._player.handsLost = tonumber(chunks[4]);

	self._player.hands = {};
	self._player.bets = {};
	for i=5, #chunks do
		local sub_chunks = {};
		for sc in chunks[i]:gmatch("[^_]+") do
			table.insert(sub_chunks, sc);
		end

		if (#sub_chunks == 2) then
			table.insert(self._player.hands, Deck.from64(sub_chunks[1]));
			table.insert(self._player.bets, tonumber(sub_chunks[2]));
		end
	end

	if (#self._player.hands < 1) then
		return false;
	else
		return true;
	end
end


function BlackjackInstance:_initializeGame(text)
	-- Exit
	if (text and text == "Cashout") then
		self:Cashout();
		return;
	end

	-- Try to initialize from a bucket first
	self:_fromBucket(self._dealer.char, self._player.char);
	if (self.status == BlackjackInstance.STATUS.ONGOING) then
		self:_status();
		return;
	end

	if (self._player.handin < self.required_payment) then
		self._dealer.char:Say(
			"You'll need to pay before you play (" .. 
			self._player.handin .. "/" .. self.required_payment .. ") [Cashout]"
		);
		self.requesting_payment = true;
		self._STAGE = BlackjackInstance._initializeGame;
		return;
	end
	self.requesting_payment = false;

	self.deck = Deck.new(1,0);
	self:getDealerHand();

	-- Draw two random cards for the player
	self._player.hands = {};
	self._player.bets = {};
	local player_hand = Deck.new(0,0);
	player_hand:addTop(self.deck:drawRandom());
	player_hand:addTop(self.deck:drawRandom());
	self:addPlayerHand(player_hand, self._player.handin);
	self._player.handin = 0;
	self.status = BlackjackInstance.STATUS.ONGOING;
	self:_status();
end


function BlackjackInstance:displayGame()
	local dia_string = "{title: Blackjack with " .. self._dealer.char:GetCleanName() .. "} ";

	-- DiaWinds really hate single custom buttons ig
	dia_string = dia_string .. "{button_one: Exit} {button_two: Forfeit} ";

	-- Window type
	dia_string = dia_string .. "wintype:1 ";

	-- Game not over --> Display error dialogue
	if (#self._player.hands > 0 and #self._outText.errorDialogue > 0) then
		dia_string = dia_string .. "{linebreak} {r}"
		for i,s in pairs(self._outText.errorDialogue) do
			dia_string = dia_string .. "{bullet} " .. s .. " ";
		end
		dia_string = dia_string .. "~ ";
	end
	self._outText.errorDialogue = {};

	-- Dealer's hand
	if (self.status == BlackjackInstance.STATUS.ONGOING) then
		dia_string = dia_string .. "{linebreak} {y} Dealer's hand: {bullet}" .. self._dealer:toStringHidden() .. "~ ";
	elseif (self.status == BlackjackInstance.STATUS.FINISHED) then
		dia_string = dia_string .. "{linebreak} {y} Dealer's hand: {bullet}" .. self._dealer.hand:toString() .. "~ ";
	end
	
	-- Hands won/lost
	dia_string = dia_string .. "{linebreak} Hands won: " .. self._player.handsWon .. " || Hands lost: " .. self._player.handsLost .. " ";

	-- Active hands
	if (#self._player.hands > 0) then
		dia_string = dia_string .. "{linebreak} {lb} Your hands: ";

		for i,hand in pairs(self._player.hands) do
			dia_string = dia_string .. " {linebreak} {in} {bullet} Val is " .. hand:optimalValue() .. 
				", bet is " .. self._player.bets[i] .. "c - " .. hand:toString() .. " ";
		end
		dia_string = dia_string .. "~ ";
	end

	-- Finished hands
	if (#self._outText.finishedHands > 0) then
		dia_string = dia_string .. "{linebreak} {gray} Finished hands: ";

		for i,fh in pairs(self._outText.finishedHands) do
			dia_string = dia_string .. "{linebreak} {in} {bullet} " .. fh .. " ";
		end
		dia_string = dia_string .. " ~ ";
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

	if (#self._player.hands < 1) then
		dia_string = dia_string .. "{linebreak} {r} GAME OVER";
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
	self._outText.optionsPrompt = "";
end


function BlackjackInstance:_status()
	for i,hand in pairs(self._player.hands) do
		local value = hand:optimalValue();
		if (hand:isBlackjack()) then
			self:_finishHand(i, self.RETURNS.BLACKJACK, "Blackjack!");
			self._player.handsWon = self._player.handsWon + 1;
		elseif (value > 21) then
			self:_finishHand(i, self.RETURNS.LOSE, "Busted!");
			self._player.handsLost = self._player.handsLost + 1;
		end
	end

	if (#self._player.hands > 0) then
		self:_turn();
	else
		self.status = BlackjackInstance.STATUS.FINISHED;
		self:displayGame();
		self:Cashout();
		self._STAGE = BlackjackInstance.displayGame;
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
	self:displayGame();
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
		while (#self._player.hands > 0) do
			self:_checkStand(1); -- Removes elements, so just use index 1 each time
		end
		self:_status();
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

		table.insert(self._outText.options, "Back");
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

		table.insert(self._outText.options, "Back");
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
		table.insert(self._outText.options, "Back");
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
			self._player.handsWon = self._player.handsWon + 1;
		end
	elseif (hand:optimalValue() == self._dealer.hand:optimalValue()) then
		self:_finishHand(hand_index, self.RETURNS.DRAW, "Tied with the dealer");
	elseif (hand:optimalValue() < self._dealer.hand:optimalValue()) then
		self:_finishHand(hand_index, self.RETURNS.LOSE, "Lost to the dealer");
		self._player.handsLost = self._player.handsLost + 1;
	else
		self:_finishHand(hand_index, self.RETURNS.WIN, "Beat the dealer!");
		self._player.handsWon = self._player.handsWon + 1;
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
	local amount = self._player.handin + self._player.due;

	addToBucket(
		self._player.char, 
		WINNINGS_FLAG .. self:getFlagSuffix(),
		self._player.due
	);

	self._player.handin = 0;
	self._player.due = 0;

	
	if (amount > 0) then
		local copp = amount % 10;
		amount = math.floor(amount / 10);
		local silv = amount % 10;
		amount = math.floor(amount / 10);
		local gold = amount % 10;
		amount = math.floor(amount / 10);
		local plat = amount;
		
		self._player.char:AddMoneyToPP(copp, silv, gold, plat, true);
	end
end