-- This is what you'll need when you place Cards.lua in quests and this file in a zone
package.path = package.path .. ";../?.lua";
-- This is for this project
package.path = package.path .. ";Project/quests/netherbian/?.lua"

require("Cards")


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
	if (self.cards[1]:isAce()) then
		return (self.cards[2]:value() == 10);
	elseif (self.cards[2]:isAce()) then
		return (self.cards[1]:value() == 10);
	else
		return false;
	end
end


local STAGE = nil;
local deck = nil;
local current_handin = 0;

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

	print(dealer_str);
	print(player_str_1);
	if (player_str_2) then
		print(player_str_2);
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
		-- Set stage to a different default
		-- Return current_handin
		return;
	end
	if (current_handin <= 0) then
		io.write("\nPlace your bet (by handing me money), or [Exit]");
		STAGE = getFirstBet;
		return;
	end

	player.hand_1_bet = current_handin;
	current_handin = 0;
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
	
	displayGame()

	-- Check if both hand are finished
	if (player.hand_1_bet == 0 and player.hand_2_bet == 0) then
		finishGame();
		return;
	end

	print();
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
	io.write(options_str);
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
			io.write("Sorry, not sure what you want.\n");
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
	if (hand ~= 1 and hand ~= 2) then hand = 0; end -- Zero means ask again or default (hand 1)

	if (player.hand_2 and hand == 0) then
		-- If player has split an ace pair and hit one of their hands, they can only hit the other
		if (player.splitAcePair and #player.hand_1.cards > 2) then
			hand = 2;
		elseif (player.splitAcePair and #player.hand_2.cards > 2) then
			hand = 1;
		else
			io.write("Select hand 1 or 2, or [Back]");
			STAGE = hit;
			return; -- End early to get the user's choice
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
	if (not player.hand_2) then
		hand = 1;
	elseif (hand ~= 1 and hand ~= 2) then 
		hand = 0; -- Zero means ask again or default (hand 1)
	end 

	if (hand == 0) then
		io.write("Select hand 1 or 2, or [Back]");
		STAGE = stand;
		return; -- End early to get the user's choice
	end

	checkStand(hand);
	endTurn();
end

-- This function actually returns instead just jumping to endTurn()
function checkStand(hand_num)
	local plrhand;
	if (hand_num == 1) then
		hand = 1;
		plrhand = player.hand_1;
	else
		hand = 2;
		plrhand = player.hand_2;
	end

	if (not plrhand) then 
		print(hand);
		return; 
	end
	
	-- Check win condition
	local str = "Hand " .. hand .. " with value " .. plrhand:optimalValue();
	if (plrhand:isBlackjack()) then
		if (dealer.hand:isBlackjack()) then
			str = str .. " tied with the dealer's blackjack!";
			-- Return bet
		else
			str = str .. " beat the dealer with a blackjack!";
			-- Triple the bet
		end
	elseif (plrhand:optimalValue() > 21) then
		str = str .. " busted!";
		-- Keep bet
	elseif (plrhand:optimalValue() < dealer.hand:optimalValue()) then
		str = str .. " lost to the dealer";
		-- Keep bet
	elseif (plrhand:optimalValue() == dealer.hand:optimalValue()) then
		str = str .. " tied with the dealer";
		-- Return bet
	else
		str = str .. " beat the dealer!";
		-- Double the bet
	end

	-- Clear correct bet
	if (hand == 1) then
		player.hand_1_bet = 0;
	else
		player.hand_2_bet = 0;
	end

	print(str);

	return;
end

-- Splits current hand into two
function split(text)
	if (text == "Back") then
		-- Return handin
		current_handin = 0;
		turn();
		return;
	end

	-- Get added bet
	if (current_handin < player.hand_1_bet) then
		io.write("You'll need at least " .. (player.hand_1_bet-current_handin) .. " more, either pay up or [Back]");
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
	player.hand_2_bet = current_handin;
	current_handin = 0;

	endTurn();
end

	
-- Print final game state and clear all game data
function finishGame()
	local dealer_str = "### Dealer - Val=" .. dealer.hand:optimalValue() .. " - " .. dealer:handToString();
	local player_str_1;
	local player_str_2;
	if (player.hand_1) then
		player_str_1 = "Player (hand 1) - Val=" .. player.hand_1:optimalValue() .. " - " .. player:handToString(1);
	end
	if (player.hand_2) then
		player_str_2 = "Player (hand 2) - Val=" .. player.hand_2:optimalValue() .. " - " .. player:handToString(2);
	end


	player.hand_1 = nil;
	player.hand_2 = nil;
	player.hand_1_bet = 0;
	player.hand_2_bet = 0;
	dealer.hand = nil;
	deck = nil;
	player.splitAcePair = false;

	-- Give any money left in current_handin
	current_handin = 0;

	getFirstBet(); -- You can never excape B L A C K J A C K
end


	-- ### MAIN CODE ### --


STAGE = getFirstBet;

getFirstBet();

-- Pseudo event_say
while true do
	io.write(" > ");
	local text = io.read();
	if not STAGE or text == "quit" then 
		break;
	-- Pseudo 
	elseif text:sub(1,1) == "m" then
		current_handin = current_handin + tonumber(text:sub(2));
		text = nil;
	end
	
	STAGE(text);
end