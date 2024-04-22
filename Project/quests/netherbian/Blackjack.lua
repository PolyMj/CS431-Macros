-- This is what you'll need when you place Cards.lua in quests and this file in a zone
	-- package.path = package.path .. ";../?.lua";
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
	local rank = self:rankID();
	if (rank < 2) then
		print("ERROR: Joker recieved in blackjack");
		return -1; -- Joker, this shouldn't happen
	elseif (rank <= 10) then -- If number card
		return rank;
	elseif (rank < 14) then -- If face card
		return 10;
	else
		return 0; -- Ace, worth either 1 or 11, whatever is best for the player
	end
end


local STAGE = nil;
local deck = nil;
local plr_hand_1 = nil;
local plr_hand_2 = nil;
local dlr_hand = nil;
local HIDDEN_CARD = "|# ## #|";

function displayGame()
	if (not dlr_hand or not plr_hand_1) then initializeGame(); end

	if (not dlr_hand or not plr_hand_1) then 
		print("Error: Game not initializing properly");
		return; 
	end

	-- Print dealers hand (1 visible 1 hidden)
	local dealer_str = dlr_hand.cards[1]:toString() .. " : " .. HIDDEN_CARD;
	
	-- Print player's hand 1
	local player_str_1 = "";
	for i, c in ipairs(plr_hand_1) do
		player_str = player_str .."[1" .. i .. "]" .. c:toString() .. "  ";
	end
	-- Print player's hand 2 (if applicable)
	local player_str_2 = "";
	if (plr_hand_2) then
		for i, c in ipairs(plr_hand_2) do
			player_str_2 = player_str .."[2" .. i .. "]" .. c:toString() .. "  ";
		end
	end

	print(dealer_str);
	print(player_str_1);
	if (player_str_2 ~= "") then
		print(player_str_2);
	end
end

function initializeGame()
	deck = Deck.new(1, 0); -- Single deck with no jokers
	plr_hand_1 = Deck.new(0,0);
	dlr_hand = Deck.new(0,0);

	plr_hand_1:addTop(deck:drawRandom());
	plr_hand_1:addTop(deck:drawRandom());
	dlr_hand:addTop(deck:drawRandom());
	dlr_hand:addTop(deck:drawRandom());
end

function turn()
	
end



STAGE = initializeGame;
while true do
	io.write(" > ");
	local text = io.read();
	if not STAGE or text == "quit" then break; end


end