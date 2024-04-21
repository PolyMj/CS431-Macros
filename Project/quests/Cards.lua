
	-- ### BEGIN CARD CLASS ### --

Card = {
	-- Adds (index-1) * 4 to the id
	RANKS = {"jo", "2", "3", "4", "5", "6", "7", "8", "9", "10", "Ja", "Q", "K", "A" };
	-- Adds (index-1) to the id
	SUITES = {"S", "H", "D", "C"};
	ID_MIN = 0;
	ID_NJ_MIN = 4;
	ID_MAX = 55;
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
	return self:rankStr() .. " of " .. self:suiteStr();
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


function Deck:toString()
	local string = "{";
	
	for i, c in pairs(self.cards) do
		string = string .. " |" .. c:toString() .. "| ";
	end
	return string .. "}";
end


	-- ### END DECK CLASS ### --