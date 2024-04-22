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


local STAGE = nil;
local deck = nil;
local current_handin = 0;

local player = {
	hand_1 = nil;
	hand_2 = nil;
	hand_1_bet = -1;
	hand_2_bet = -1;
	splitAcePair = false;
};

local dealer = {
	hand = nil;
}

-- Display all cards (display hidden cards as face down)
function displayGame()
	if (not dealer.hand or not player.hand_1) then initializeGame(); end

	if (not dealer.hand or not player.hand_1) then 
		print("Error: Game not initializing properly");
		return; 
	end

	-- Print dealers hand (1 visible 1 hidden)
	local dealer_str = "Dealer - " .. dealer.hand.cards[1]:toString() .. " : " .. dealer.hand.cards[2]:toStringFaceDown();
	
	-- Print player's hand 1
	local player_str_1 = "Player (hand 1) - ";
	if (player.hand_1_bet > 0) then
		for i, c in ipairs(player.hand_1.cards) do
			player_str_1 = player_str_1 .."[1" .. i .. "]" .. c:toString() .. "  ";
		end
	else
		player_str_1 = player_str_1 .. "Finished";
	end

	-- Print player's hand 2 (if applicable)
	local player_str_2 = nil;
	if (player.hand_2) then
		player_str_2 = "Player (hand 2) - ";
		if (player.hand_2_bet > 0) then
			for i, c in ipairs(player.hand_2.cards) do
				player_str_2 = player_str_2 .."[2" .. i .. "]" .. c:toString() .. "  ";
			end
		else
			player_str_2 = player_str_2 .. "Finished";
		end
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

function getFirstBet(text)
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
	-- Check if player lost or won (hand_1)
	if (player.hand_1_bet > 0) then
		if (player.hand_1:minValue() == 21) then
			-- Give player their bet for hand_1
			win(1);
		elseif (player.hand_1:minValue() > 21) then
			lose(1);
		end
	end
	-- Check if player lost or won (hand_1)
	if (player.hand_2_bet > 0) then
		if (player.hand_2:minValue() == 21) then
			-- Give player their bet for hand_2
			win(2);
		elseif (player.hand_2:minValue() > 21) then
			lose(2);
		end
	end
	
	displayGame()

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
		return;
	else
		turn();
	end
end

-- Player options:
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
-- 

-- Draw another card for one of the player's hands
function hit(text)
	local hand = tonumber(text or "0");
	if (hand ~= 1 and hand ~= 2) then hand = 0; end -- Zero means ask again or default (hand 1)

	if (player.hand_2 and hand == 0) then
		-- If player has split an ace pair and hit one of their hands, they can only hit the other
		if (player.splitAcePair and #player.hand_1.cards > 2) then
			hand = 2;
		elseif (player.splitAcePair and #player.hand_2.cards > 2) then
			hand = 1;
		else
			io.write("Select hand 1 or 2");
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
function stand()

	endTurn();
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
	print("Created hand 2");
	if (player.hand_2) then
		print("Hand 2 is valid");
	else
		print("Hand 2 is nil");
	end

	endTurn();
end

-- Win for the given hand
function win(hand_num)
	if (not hand_num) then
		print("ERROR: Nil handnum recieved in win()");
		return
	elseif not (hand_num == 1 or hand_num == 2) then
		print("ERROR: Invalid handnum recieved in win()");
		return;
	end

	print("You won hand " .. hand_num .. "!");
	if (hand_num == 1) then
		-- Return bet
		player.hand_1_bet = 0;
	else
		-- Return bet
		player.hand_2_bet = 0;
	end

	if (player.hand_1_bet == 0 and player.hand_2_bet == 0) then
		finishGame();
	end
end

-- Lose for the given hand
function lose(hand_num)
	if (not hand_num) then
		print("ERROR: Nil handnum recieved in lose()");
		return
	elseif not (hand_num == 1 or hand_num == 2) then
		print("ERROR: Invalid handnum recieved in lose()");
		return;
	end

	print("You lost hand " .. hand_num .. ".");
	if (hand_num == 1) then
		player.hand_1_bet = 0;
	else
		player.hand_2_bet = 0;
	end

	if (player.hand_1_bet == 0 and player.hand_2_bet == 0) then
		finishGame();
	end
end

-- Clear all game data
function finishGame()
	player.hand_1 = nil;
	player.hand_2 = nil;
	player.hand_1_bet = -1;
	player.hand_2_bet = -1;
	dealer.hand = nil;
	deck = nil;
	player.splitAcePair = false;

	-- Give any money left in current_handin
	current_handin = 0;

	initializeGame(); -- You can never excape B L A C K J A C K
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