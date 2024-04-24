local npc;
local client;

local player_due = 0;
local player_handin = 0;
local paying = false;

local STAGE = nil;

FLAG_WINNINGS = "-GFWINNINGS";
FLAG_WAGERED = "-GFWAGERED";

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
	RANK_FULL_NAME = {"Joker", "Ace", "2", "3", "4", "5", "6", "7", "8", "9", "10", "Jack", "Queen", "King"};
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
	if (#self.cards <= 0) then return nil end;
	local index = math.random(1,#self.cards);
	local card = self.cards[index];
	table.remove(self.cards, index);
	return card;
end

-- Returns a random card without removing it
function Deck:peekRandom()
	local index = math.random(1,#self.cards);
	local card = self.cards[index];
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

function Deck:count()
	return #self.cards;
end

-- Prints the entire deck (subject to change)
function Deck:toString()
	local string = "{:";
	
	for i, c in pairs(self.cards) do
		string = string .. " " .. c:toString() .. " :";
	end
	return string .. "}";
end


-- Adds all matching rank cards from otherDeck to self, and returns the number of cards found
function Deck:haveAny(otherDeck, rankID)
	local count = 0;
	local i = 1;
	while (i <= #otherDeck.cards) do
		if (otherDeck.cards[i]:rankID() == rankID) then
			local card = otherDeck.cards[i];
			table.remove(otherDeck.cards, i);
			self:addTop(card);
			count = count + 1;
		else
			i = i + 1;
		end
	end
	return count;
end

	-- ### END DECK CLASS ### --



local deck = nil;

local player = {
	hand = nil;
};

local kid = {
	hand = nil;
};


function displayGame()
	npc:Say("Your hand: " .. player.hand:toString());
end


function initalizeGoFish()
	player.hand = Deck.new(0, 1);
	kid.hand = Deck.new(0, 1);
	deck = Deck.new(1,1);

	-- Seven cards each
	for i=1, 7 do
		player.hand:addTop(deck:drawRandom());
		kid.hand:addTop(deck:drawRandom());
	end

	npc:Say("Let's get started!");
	parseRank();
end


function checkStatus()
	if (player.hand:count() <= 0) then
		npc:Say("Win");
	elseif (kid.hand:count() <= 0) then
		npc:Say("Lose");
	elseif (deck:count() <= 0) then
		if (player.hand:count() < kid.hand:count()) then
			npc:Say("Win");
		elseif (player.hand:count() < kid) then
			npc:Say("Tie");
		else
			npc:Say("Lose");
		end
	-- Game not over
	else
		parseRank();
	end

end

function createPlayerPrompt()
	local ask_for = "You say \"Have any...\"";
	-- For all card ranks
	for i,n in ipairs(Card.RANK_FULL_NAME) do
		-- For all cards the player has
		for j,c in ipairs(player.hand.cards) do
			-- If the player has the rank, add it as an option
			if (c:rankID() == i-1) then
				ask_for = ask_for .. " [" .. n .. "]s";
				break;	
			end
		end
	end
	return ask_for;
end

function parseRank(text)
	if (not deck) then
		initalizeGoFish();
		return;
	end

	if (not text) then
		displayGame();

		npc:Say(createPlayerPrompt());
		STAGE = parseRank;
		return;
	end

	local rankID = -1;
	
	for i,c in ipairs(Card.RANK_FULL_NAME) do
		if (text == c) then
			rankID = i-1;
			break;
		end
	end

	local has_rank = false;
	for i,c in ipairs(player.hand.cards) do
		if (c:rankID() == rankID) then
			has_rank = true;
			break;
		end
	end

	if (not has_rank) then
		npc:Say("You don't have one of those cards! Wha- don't ask me how I know!");
		parseRank();
		return;
	end

	if (rankID ~= -1) then
		singleRound(rankID);
	else
		npc:Say("Sorry, didn't catch that");
	end
end


function singleRound(rankID)
	if (rankID < 0 or rankID > Card.RANK_IDS.KING) then
		npc:Say("Sorry, not sure what card that is");
		return;
	end

	local player_found = player.hand:haveAny(kid.hand, rankID);
	if (player_found > 0) then
		npc:Say("I had " .. player_found .. " " .. Card.RANK_FULL_NAME[rankID+1] .. "s");
	else
		npc:Say("Nope! Go fish!");
		player.hand:addTop(deck:drawRandom());
	end

	-- Pick a rank starting from the rank of one of the player's cards (damn kid's cheating)
	local npc_search = player.hand:peekRandom():rankID();
	local found = false;
	while not found do
		for i,c in ipairs(kid.hand.cards) do
			if (c:rankID() == npc_search) then
				found = true;
				break;
			end
		end
		npc_search = (npc_search + 1) % #Card.RANKS;
	end

	npc:Say("Have any " .. Card.RANK_FULL_NAME[npc_search+1] .. "s?");

	local npc_found = kid.hand:haveAny(player.hand, npc_search);
	if (npc_found > 0) then
		npc:Say("Found " .. npc_found .. " " .. Card.RANK_FULL_NAME[npc_search+1] .. "s");
	else
		npc:Say("Darnit! I'll go fish...");
		kid.hand:addTop(deck:drawRandom());
	end

	checkStatus();
end



STAGE = parseRank;

function event_say(e)
	npc = e.self;
	client = e.other;
	if (paying) then
		-- Pay
	end
	
	-- Get payment from player
	if (paying) then
		parseMoney(e.message);
	end

	-- Return to relevant stage of blackjack
	STAGE(e.message);

	-- Give player option to cash out if they're owed money
	if (player_due+player_handin > 0) then
		npc:Say("Current winnings/owed - " .. player_due+player_handin .. "c [Cash Out]");
	end
end

function event_trade(e)
	local item_lib = require("items");
	item_lib.return_items(e.self, e.other, e.trade);
end