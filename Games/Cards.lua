math.randomseed(os.time())


	-- ### BEGIN CARD CLASS ### --

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


	-- ### END DECK CLASS ### --