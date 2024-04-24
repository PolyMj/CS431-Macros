local npc;
local client;

local player_due = 0;
local player_handin = 0;
local paying = false;

FLAG_WINNINGS = "-BJWINNINGS";
FLAG_WAGERED = "-BJWAGERED";

function addToDB(flag, amount)
	if (not flag or not amount) then
		print("ERROR: Cannot add with nil flag/amount");
		return;
	end

	local FULL_FLAG = client:AccountID() .. flag

	local original = (tonumber(client:GetBucket(FULL_FLAG)) or 0);
	client:SetBucket(FULL_FLAG, tostring(amount+original));
end

function returnMoney(cl)
	cl = cl or client;
	if (not cl) then return; end

	local total = (player_due or 0) + (player_handin or 0);
	
	local copper = total % 10;
	total = math.floor(total / 10);
	local silve = total % 10;
	total = math.floor(total / 10);
	local gold = total % 10;
	total = math.floor(total / 10);
	local platinum = total % 10;
	cl:AddMoneyToPP(copper, silve, gold, platinum, true);
	player_due = 0;
	player_handin = 0;
end

-- Get payment amount from player (in copper)
function parseMoney(text)
	paying = false;
	if (not text) then
		return;
	end

	local amount = tonumber(text);
	if (amount and amount > 0) then
		if (client:TakeMoneyFromPP(amount, true)) then
			player_handin = player_handin + amount;
		end
	end
end


	-- ### BEGIN CARD CLASS ### --

math.randomseed(os.time())

Card = {
	-- Adds (index-1) * 4 to the id
	RANKS = {"jo", "A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "Ja", "Q", "K"};
	-- Adds (index-1) to the id
	SUITES = {"S", "H", "D", "C"};
	ID_MIN = 0;
	ID_NJ_MIN = 4;
	ID_MAX = 55;
	
	RANK_IDS = {
		JOKER = 0;
		JACK = 11;
		QUEEN = 12;
		KING = 13;
		ACE = 1;
		TWO = 2;
		TEN = 10;
	};
};
Card.__index = Card;

-- Creates a card new card from an ID
function Card.new(id)
	local self = setmetatable({}, Card);

	if (type(id) == "number" and 0 <= Card.ID_MIN and id <= Card.ID_MAX) then
		self.id = id;
	else
		return nil;
	end

	return self;
end


function Card:suiteID() return self.id % 4 end;
function Card:suiteStr() return self.SUITES[self:suiteID()+1] end;

function Card:rankID() return math.floor(self.id / 4); end
function Card:rankStr() return self.RANKS[self:rankID()+1] end;

function Card:toString()
	return "|" .. self:rankStr() .. " of " .. self:suiteStr() .. "|";
end

function Card:toStringFaceDown()
	return "|%###%|";
end

function Card.faceDownCard()
	return "|%###%|";
end

function Card:isAce()
	return (self:rankID() == Card.RANK_IDS.ACE);
end

function Card:isFace()
	local rank = self:rankID();
	return (rank == Card.RANK_IDS.JACK or
			rank == Card.RANK_IDS.QUEEN or
			rank == Card.RANK_IDS.KING
	);
end

function Card:isNumber()
	local rank = self:rankID();
	return (Card.RANK_IDS.TWO <= rank or rank <= Card.RANK_IDS.TEN);
end

	-- ### END CARD CLASS ### --



	-- ### BEGIN DECK CLASS ### --
Deck = { };
Deck.__index = Deck;
-- Create a new deck of cards
function Deck.new(deck_count, use_joker)
	local self = setmetatable({}, Deck);
	self.cards = {};
	
	local count = deck_count or 0; -- Default to empty deck
	local jokers = use_joker or 0; -- Default to no jokers
	
	local range_min = Card.ID_MIN;
	local range_max = Card.ID_MAX
	if (jokers) then range_min = Card.ID_NJ_MIN end;
	
	-- Generate [count] decks of cards
	for n=1, count do
		for id=range_min, range_max do
			local card = Card.new(id);
			if (card) then
				table.insert(self.cards, card);
			end
		end
	end

	return self;
end

-- Draws and returns a random card, removing it from the deck
function Deck:drawRandom()
	local index = math.random(1,#self.cards);
	local card = self.cards[index];
	table.remove(self.cards, index);
	return card;
end

-- Inserts a card into a random location in the deck
function Deck:insertRandom(card)
	table.insert(self.cards, math.random(1,#self.cards+1), card);
end

-- Shuffles the deck (see drawRandom(), you may not need to shuffle)
function Deck:shuffle(count)
	local count = count or 3;
	for i=1, count do
		for c=1, #self.cards do
			self:addTop(self:drawRandom()); -- Draws a random card and reinserts it
		end
		for c=1, #self.cards do
			self:insertRandom(self:drawTop()) -- Draws the top card and randomly reinserts it
		end
	end
end

-- draws a card from the top of the deck
function Deck:drawTop()
	local card = self.cards[#self.cards];
	table.remove(self.cards);
	return card;
end

-- Add a card to the top of the deck
function Deck:addTop(card)
	table.insert(self.cards, card);
end

-- Prints the entire deck (subject to change)
function Deck:toString()
	local string = "{:";
	
	for i, c in pairs(self.cards) do
		string = string .. " " .. c:toString() .. " :";
	end
	return string .. "}";
end


	-- ### END DECK CLASS ### --


	-- ### BEGIN BLACKJACK ### --

-- Blackjack guide
	-- Player places their bet
	-- Dealer deals two cards to each player including themselves
		-- One of the dealer's cards is face-up
		-- Player's cards are face-up
	-- Player's options:
		-- Stand
			-- You feel you're close enough with the cards you have.
		-- Hit
			-- Recieve another card
			-- As many as you want until you stand
		-- Splitting pairs
			-- If your first two cards have the same numerical value, you may split them into two hands
				-- Each hand will be like it's own game, but only with stand and hit
				-- The bet on each must equal the original bet
				-- If the pair is of aces, you are limited to one card draw on each hand
		-- Doubling down
			-- Double your bet and recieve exactly one more card
		-- Insurance
			-- If the dealer's face-up is an Ace, you may bet half of your original bet that the dealer has a blackjack
		-- Surrender
			-- Take the L but only give half your wager

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


local STAGE = nil;
local deck = nil;

local player = {
	hand_1 = nil;
	hand_2 = nil;
	hand_1_bet = 0;
	hand_2_bet = 0;
	splitAcePair = false;

	-- Use either 1 or 2 to get hand 1/2
	handToString = function(self, hand_num)
		local hand = self.hand_2;
		local bet = self.hand_2_bet;
		if not (hand_num and hand_num == 2) then
			hand_num = 1;
			hand = self.hand_1;
			bet = self.hand_1_bet;
		end

		if (not hand) then return " - "; end

		local str = "Player (hand " .. hand_num .. ") - ";
		if (bet <= 0) then
			str = str .. "Finished - " .. hand:toString();
		else
			str = str .. "Val=" .. hand:optimalValue() .. " " .. hand:toString() .. " | Bet = " .. bet .. "c";
		end
		return str;
	end
};

local dealer = {
	hand = nil;
	character = nil;

	handToString = function(self)
		return (
			"### Dealer - Val>=" .. self.hand.cards[1]:value() .. " : " .. 
			self.hand.cards[1]:toString() .. Card.faceDownCard() .. 
			" | Total bet = " .. (player.hand_1_bet + player.hand_2_bet) .. "c"
		);
	end
}

-- Display all cards (display hidden cards as face down)
function displayGame()
	if (not dealer.hand or not player.hand_1) then initializeGame(); end

	if (not dealer.hand or not player.hand_1) then 
		print("Error: Game not initializing properly");
		return; 
	end

	-- Print dealers hand (1 visible 1 hidden)
	local dealer_str = dealer:handToString();
	
	local player_str_1;
	if (player.hand_1) then
		player_str_1 = player:handToString(1);
	end

	local player_str_2;
	if (player.hand_2) then
		player_str_2 = player:handToString(2);
	end

	npc:Say(dealer_str);
	npc:Say(player_str_1);
	if (player_str_2) then
		npc:Say(player_str_2);
	end
end

-- Create decks and draw initial cards
function initializeGame()
	deck = Deck.new(1, 0); -- Single deck with no jokers

	player.hand_1 = Deck.new(0,0);
	player.hand_1:addTop(deck:drawRandom());
	player.hand_1:addTop(deck:drawRandom());
	player.splitAcePair = false;

	dealer.hand = Deck.new(0,0);
	dealer.hand:addTop(deck:drawRandom());
	dealer.hand:addTop(deck:drawRandom());

	endTurn(); -- Basically after turn 0 I guess idk
end

-- Get a bet before the game starts
function getFirstBet(text)
	if (text and text == "Back") then
		player_due = player_due + player_handin;
		return;
	end
	if (player_handin <= 0) then
		npc:Say("Place your bet on a game of blackjack (say amount in copper)");
		paying = true;
		STAGE = getFirstBet;
		return;
	elseif (player_handin < 200) then
		npc:Say("Nah " .. player_handin .. " won't cut it, I need at least 200c");
		paying = true;
		STAGE = getFirstBet;
		return;
	end

	player.hand_1_bet = player_handin;
	addToDB(FLAG_WAGERED, player_handin);
	player_handin = 0;
	initializeGame();
end

-- Checks game status after a turn and acts accordingly
function endTurn()
	
	-- If a hand >= 21, force a stand for that hand
	if (player.hand_1_bet > 0) then
		if (player.hand_1:optimalValue() >= 21) then
			checkStand(1);
		end
	end
	if (player.hand_2_bet > 0) then
		if (player.hand_2:optimalValue() >= 21) then
			checkStand(2);
		end
	end

	-- Check if both hand are finished
	if (player.hand_1_bet == 0 and player.hand_2_bet == 0) then
		finishGame();
		return;
	end
	
	displayGame()

	-- print();
	turn();
end

-- For displaying turn options to the user
function turn()
	local options_str = "[Stand]"; -- Stand is always an option

	-- If the player hasn't split an ace pair and hit once for each deck
	if not (player.splitAcePair and (#player.hand_1.cards < 3 or #player.hand_2.cards < 3)) then
		options_str = options_str .. " [Hit]";
	end

	-- If the player hasn't split already
	if (not player.hand_2) then
		options_str = options_str .. " [Split]";
	end

	-- Display options and prepare to parse/listen for them
	npc:Say(options_str);
	STAGE = parseTurn;
end

-- Parses the user's turn decision
function parseTurn(text)
	if (text) then
		if (text == "Split") then
			split();
		elseif (text == "Hit") then
			hit();
		elseif (text == "Stand") then
			stand();
		else
			npc:Say("Sorry, not sure what you want.\n");
			displayGame();
			turn();
		end
		return; -- Make sure to return if calling a turn function like hit() or split()
	else
		turn();
	end
end

-- Draw another card for one of the player's hands
function hit(text)
	if (text and text == "Back") then
		turn();
		return;
	end

	local hand = tonumber(text or "0");
	if (not hand or (hand ~= 1 and hand ~= 2)) then hand = 0; end -- Zero means ask again or default (hand 1)

	-- If player hasn't selected
	if (hand == 0) then
		-- If only one hand is in play
		if (player.hand_1_bet <= 0) then
			hand = 2;
		elseif (player.hand_2_bet <= 0) then
			hand = 1;
		-- Both hands in play:
		else
			-- If player has split an ace pair and hit one of their hands, they can only hit the other
			if (player.splitAcePair and #player.hand_1.cards > 2) then
				hand = 2;
			elseif (player.splitAcePair and #player.hand_2.cards > 2) then
				hand = 1;
			-- Player simply hasn't chosen their hand, both are available
			else
				npc:Say("Select hand [1] or [2], or go [Back]");
				STAGE = hit;
				return; -- End early to get the user's choice
			end
		end
	end

	if (hand <= 1) then
		player.hand_1:addTop(deck:drawRandom());
	else
		player.hand_2:addTop(deck:drawRandom());
	end

	endTurn();
end

-- Player chooses to use the cards they have; check value of cards and compare to dealer
function stand(text)
	if (text and text == "Back") then
		turn();
		return;
	end

	local hand = tonumber(text or "0");
	if (player.hand_2_bet <= 0) then
		hand = 1;
	elseif (player.hand_1_bet <= 0) then
		hand = 2;
	elseif (hand ~= 1 and hand ~= 2) then 
		hand = 0; -- Zero means ask again or default (hand 1)
	end 

	if (hand == 0) then
		npc:Say("Select hand [1] or [2], or go [Back]");
		STAGE = stand;
		return; -- End early to get the user's choice
	end

	checkStand(hand);
	endTurn();
end

-- This function actually returns instead just jumping to endTurn()
function checkStand(hand_num)
	local plrhand;
	local bet;
	if (hand_num == 1) then
		hand = 1;
		plrhand = player.hand_1;
		bet = player.hand_1_bet;
		player.hand_1_bet = 0;
	else
		hand = 2;
		plrhand = player.hand_2;
		bet = player.hand_2_bet;
		player.hand_2_bet = 0;
	end

	if (not plrhand) then 
		return; 
	end
	
	-- Check win condition
	local str = "Hand " .. hand .. " with value " .. plrhand:optimalValue();
	if (plrhand:isBlackjack()) then
		if (dealer.hand:isBlackjack()) then
			str = str .. " tied with the dealer's blackjack!";
			-- Return bet
			player_due = player_due + bet;
		else
			str = str .. " beat the dealer with a blackjack!";
			-- Triple the bet
			player_due = player_due + 3*bet;
		end
	elseif (plrhand:optimalValue() > 21) then
		str = str .. " busted!";
		-- Keep bet (don't change player_due)
	elseif (plrhand:optimalValue() < dealer.hand:optimalValue()) then
		str = str .. " lost to the dealer";
		-- Keep bet (don't change player_due)
	elseif (plrhand:optimalValue() == dealer.hand:optimalValue()) then
		str = str .. " tied with the dealer";
		-- Return bet
		player_due = player_due + bet;
	else
		str = str .. " beat the dealer!";
		-- Double the bet
		player_due = player_due + 2*bet;
	end


	npc:Say(str);

	return;
end

-- Splits current hand into two
function split(text)
	if (text == "Back") then
		-- Return handin
		player_handin = 0;
		turn();
		return;
	end

	-- Get added bet
	if (player_handin < player.hand_1_bet) then
		npc:Say("You'll need at least " .. (player.hand_1_bet-player_handin) .. " more, either pay up or [Back]");
		paying = true;
		STAGE = split;
		return;
	end

	-- Will need to add a section for doubling the bet here
	-- If both cards are aces
	if (player.hand_1.cards[1]:isAce() and player.hand_1.cards[2]:isAce()) then
		player.splitAcePair = true;
	end

	-- Perform split
	player.hand_2 = Deck.new(0,0);
	player.hand_2:addTop(player.hand_1:drawTop());
	player.hand_2_bet = player_handin;
	addToDB(FLAG_WAGERED, player_handin);
	player_handin = 0;

	endTurn();
end

	
-- Print final game state and clear all game data
function finishGame()
	local dealer_str = "### Dealer - Val=" .. dealer.hand:optimalValue() .. " - " .. dealer.hand:toString();
	local player_str_1;
	local player_str_2;
	if (player.hand_1) then
		player_str_1 = "Player (hand 1) - Val=" .. player.hand_1:optimalValue() .. " - " .. player:handToString(1);
	end
	if (player.hand_2) then
		player_str_2 = "Player (hand 2) - Val=" .. player.hand_2:optimalValue() .. " - " .. player:handToString(2);
	end

	npc:Say("GAME OVER");
	npc:Say(dealer_str);
	if (player_str_1) then
		npc:Say(player_str_1);
	end
	if (player_str_2) then
		npc:Say(player_str_2);
	end

	player.hand_1 = nil;
	player.hand_2 = nil;
	player.hand_1_bet = 0;
	player.hand_2_bet = 0;
	dealer.hand = nil;
	deck = nil;
	player.splitAcePair = false;

	-- Give any money left in player_handin
	addToDB(FLAG_WINNINGS, player_due);
	returnMoney();

	getFirstBet(); -- You can never excape B L A C K J A C K
end


	-- ### MAIN CODE ### --



-- EVENT STUFF
STAGE = getFirstBet;

function event_say(e)
	npc = e.self;
	client = e.other;

	-- Pay player back
	if (e.message == "Cash Out") then
		returnMoney(client);
	end

	if (e.message == "Stats") then
		npc:Say("Total winnings - " .. client:GetBucket((client:AccountID()) .. FLAG_WINNINGS));
		npc:Say("Total wagered - " .. client:GetBucket((client:AccountID()) .. FLAG_WAGERED));
		return;
	end
	
	-- Get payment from player
	if (paying) then
		parseMoney(e.message);
	end

	-- Return to relevant stage of blackjack
	STAGE(tostring(e.message));

	-- Give player option to cash out if they're owed money
	if (player_due+player_handin > 0) then
		npc:Say("Current winnings/owed - " .. player_due+player_handin .. "c [Cash Out]");
	end
end

function event_trade(e)
	local item_lib = require("items");
	item_lib.return_items(e.self, e.other, e.trade);
end