package.path = package.path .. ";/home/eqemu/server/quests/?.lua";
require("Cards");

GOFISH_FLAG = "-GoFish";

math.randomseed(os.time())


-- Adds all matching rank cards from otherDeck to self, and returns the number of cards found
function Deck:fishAny(otherDeck, rankID)
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

function Deck:hasAny(rankID)
	for i,card in pairs(self.cards) do
		if (card:rankID() == rankID) then
			return true;
		end
	end
	return false;
end

function Deck:findRemoveSet(rankID)
	local unfound = {1, 2, 3, 4};
	local base_id = rankID * 4;
	local found_indices = {};
	for ci,card in pairs(self.cards) do
		-- If the rank id matches
		if (card:rankID() == rankID) then
			local ui = 1;
			-- Check if it matches an unfound suite
			while (ui <= #unfound) do
				local id = unfound[ui] + base_id;
				if (id == card.id) then
					table.insert(found_indices, ci);
					table.remove(unfound(ui))
				end
			end
		end
	end

	if (#found_indices == 4) then
		for i,f in pairs(found_indices) do
			table.remove(self.cards, f-i+1);
		end
		return true;
	end
	return false;
end


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


GoFishInstance = {};
GoFishInstance.__index = GoFishInstance;
function GoFishInstance.new(npc, client, required_payment, deck_count, inital_card_count)
	self = setmetatable({}, GoFishInstance);

	if (not client or not npc) then
		return nil;
	end

	self.required_payment = required_payment or 0;
	self.requesting_payment = false;

	self.deck = nil;
	self.deck_count = deck_count or 1;
	if (self.deck_count < 1) then self.deck_count = 1 end

	self.initial_card_count = inital_card_count or 7;
	if (self.initial_card_count < 1) then self.initial_card_count = 1 end

	self._player = {
		char = client;
		handin = 0;
		due = 0;
		bet = 0;
		hand = nil
	};

	self._npc = {
		char = npc;
		hand = nil;
	};

	self._outText = {
		errorDialogue = {};
		options = {};
		optionsPrompt = nil;
		playerAskResult = nil;
		npcAskResult = nil;
		playerFindSet = nil;
		npcFindSet = nil;
	};

	self.gameOverStatus = nil; -- nil ==> Game ongoing

	self.RETURNS = {
		LOSE = 0;
		DRAW = 1;
		WIN = 2;
	};

	self.playerFish = GoFishInstance.defaultFish;
	self.npcFish = GoFishInstance.defaultFish;

	self.npcAsk = GoFishInstance.defaultNpcAsk;

	self._STAGE = GoFishInstance._initializeGame;

	return self;
end


-- Adds amount_copper to the player's handin total
function GoFishInstance:handin(amount_copper)
	if (amount_copper > 0) then
		self._player.handin = self._player.handin + (amount_copper or 0);
	end
end

-- Forces the player to pay against their will
function GoFishInstance:forceHandin(amount_copper)
	if (amount_copper > 0) then
		if (self._player.char:TakeMoneyFromPP(amount_copper, true)) then
			self._player.handin = self._player.handin + (amount_copper or 0);
		end
	end
end

-- Default fish mechanics for NPC. Returns a card taken from the deck. 
function GoFishInstance:defaultFish()
	return self.deck:drawRandom();
end

-- Returns the rankID of what npc wants to ask for
function GoFishInstance:defaultNpcAsk()
	return self._npc.hand:peekRandom():rankID();
end

-- Load data from a bucket. If data not found or invalid, initialize to new game
function GoFishInstance:_fromBucket(npc, client)
	local FLAG = BLACKJACK_FLAG .. npc:GetName() .. client:AccountID();
	local data = client:GetBucket(FLAG);

	-- Incomplete
end

function GoFishInstance:_parseBucket(data)
	-- Incomplete
end

function GoFishInstance:_initializeGame()
	-- Check / request payment
	if (self._player.handin < self.required_payment) then
		self._npc.char:Say(
			"You'll need to pay before you play (" .. 
			self._player.handin .. "/" .. self.required_payment .. ")"
		);
		self.requesting_payment = true;
		self._STAGE = GoFishInstance._initializeGame;
		return;
	end

	-- Initialize deck
	self.deck = Deck.new(self.deck_count, 1);

	-- Initialize hands
	self._npc.hand = Deck.new(0,0);
	self._player.hand = Deck.new(0,0);

	-- Fish out the cards for player and npc
	for i=1, self.initial_card_count do
		self:_npcGoFish();
		self:_playerGoFish();
	end

	-- Set bet and reset player handin
	self._player.bet = self._player.handin;
	self._player.handin = 0;
	self:_status();
end


-- Gameplay

function GoFishInstance:go(text, client)
	-- Checks if passed in client matches current. If not, save other game and create new game
	if (client and self._player.char:AccountID() ~= client:AccountID()) then
		self:exit();
		self:_fromBucket(self._npc.char, client);
		return;
	end

	if (text and text == "Exit" and #self._player.hand > 0) then
		self._npc.char:Say("Game saved");
		self:exit();
		return;
	end

	self:_STAGE(text);
end


function GoFishInstance:_status()
	-- Check win/lose/draw
	if (self._player.hand:count() <= 0) then
		self._outText.gameOverStatus = "YOU LOSE";
		payClient(self._player.char, math.floor(self._player.bet * self.RETURNS.LOSE))
	elseif (self._npc.hand:count() <= 0) then
		self._outText.gameOverStatus = "YOU WIN!";
		payClient(self._player.char, math.floor(self._player.bet * self.RETURNS.WIN))
	elseif (self.deck:count() <= 0) then
		if (self._player.hand:count() < self._npc.hand:count()) then
			self._outText.gameOverStatus = "YOU LOSE";
			payClient(self._player.char, math.floor(self._player.bet * self.RETURNS.LOSE))
		elseif (self._player.hand:count() == self._npc.hand:count()) then
			self._outText.gameOverStatus = "It's a draw!";
			payClient(self._player.char, math.floor(self._player.bet * self.RETURNS.DRAW))
		else
			self._outText.gameOverStatus = "YOU WIN!";
			payClient(self._player.char, math.floor(self._player.bet * self.RETURNS.WIN))
		end
	end
	
	if (not self.gameOverStatus) then
		self:_turn();
	else
		self:displayGame();
		self:Cashout();
		self._STAGE = GoFishInstance._initializeGame;
	end
end

function GoFishInstance:displayGame()
	local dia_string = "{title: Go Fish with " .. self._npc.char:GetCleanName() .. "} ";

	-- DiaWinds really hate single custom buttons ig
	dia_string = dia_string .. "{button_one: Exit} {button_two: Exit} ";

	-- Window type
	dia_string = dia_string .. "wintype:1 ";

	-- Deck
	if (self.deck:count() > 0) then
		dia_string = dia_string .. "{linebreak} The deck has around " ..
			(math.random(1, self.deck:count()) + math.random(1, self.deck:count())) ..
			" cards ~ ";
	else
		dia_string = dia_string .. "{linebreak} The deck is empty ";
	end

	-- NPC's hand
	if (self.deck:count() > 0) then
		dia_string = dia_string .. "{linebreak} {y} " .. self._npc.char:GetCleanName() .. " has around " ..
			(math.random(1, self._npc.hand:count()) + math.random(1, self._npc.hand:count())) ..
			" cards ~ ";
	else
		dia_string = dia_string .. "{linebreak} {y} " .. self._npc.char:GetCleanName() .. "'s hand is empty ~ ";
	end

	-- Player's hand
	if (self._player.hand:count() > 0) then
		dia_string = dia_string .. "{linebreak} {lb} Your cards";
		for i,c in pairs(self._player.hand.cards) do
			dia_string = dia_string .. " {bullet} " .. c:toFullString();
		end
		dia_string = dia_string .. " ~ ";
	else
		dia_string = dia_string .. "{linebreak} {lb} " .. "Your hand is empty ~ ";
	end

	-- Results of player's ask
	if (self._outText.playerAskResult) then
		dia_string = dia_string .. "{linebreak} {g} " .. self._outText.playerAskResult .. " ~ ";
	end
	self._outText.playerAskResult = nil;
	-- Result of npc's ask
	if (self._outText.npcAskResult) then
		dia_string = dia_string .. "{linebreak} {r} " .. self._outText.npcAskResult .. " ~ ";
	end
	self._outText.npcAskResult = nil;

	-- If game over
	if (self.gameOverStatus) then
		dia_string = dia_string .. "{linebreak} {r} " .. (self.gameOverStatus) .. " ";
	-- Else display error dialogue
	else
		if (#self._outText.errorDialogue > 0) then
			dia_string = dia_string .. "{linebreak} {r}";
			for i,v in pairs(self._outText.errorDialogue) do
				dia_string = dia_string .. " {bullet} " .. v
			end
			dia_string = dia_string .. " ~ ";
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
		self._npc.char:Say(options_string);
	end
	self._outText.options = {};
	self._outText.optionsPrompt = "";
end


function GoFishInstance:_turn()
	-- Find all unique ranks in player's hand
	for ri, rank in pairs(Card.RANK_FULL_NAMES) do
		if (self._player.hand:hasAny(ri-1)) then
			table.insert(self._outText.options, rank .. "s");
		end
		self._outText.optionsPrompt = "You ask \" Have any...\" ";
	end

	self._STAGE = GoFishInstance._parseTurn;
	self:displayGame();
end


function GoFishInstance:_parseTurn(text)
	if (not text) then
		self:_turn();
		return;
	end

	local rankID = -1;
	for i,rank in pairs(Card.RANK_FULL_NAMES) do
		-- Find the rankID of the rank said by the player
		if (text:sub(1,#text-1) == rank) then
			rankID = i-1;
		end
	end

	-- If not a rank
	if (rankID < 0 or rankID > Card.RANK_IDS.KING) then
		table.insert(self._outText.errorDialogue, "Sorry, don't know what rank that is ID:" .. rankID);
		self:_turn();
		return;
	end

	-- If player does not have that rank
	if (not self._player.hand:hasAny(rankID)) then
		table.insert(self._outText.errorDialogue, "You don't have any " .. text .. "! Don't ask me how I know...");
		self:_turn();
		return;
	end

	-- Fish from _npc.hand to _player.hand
	local foundCount = self._player.hand:fishAny(self._npc.hand, rankID);
	if (foundCount > 0) then
		self._outText.playerAskResult = "You found " .. foundCount .. " " .. Card.RANK_FULL_NAMES[rankID+1] .. "s ";
		if (self._player.hand:findRemoveSet(rankID)) then
			self._outText.playerFindSet = "You found all the " .. Card.RANK_FULL_NAMES[rankID+1] .. "s! ";
		end
	else
		self._outText.playerAskResult = "You didn't find any " .. Card.RANK_FULL_NAMES[rankID+1] .. "... Go fish! ";
		self:_playerGoFish();
	end

	self:_npcsTurn();
end


function GoFishInstance:_npcsTurn()
	local rankID = self:npcAsk();

	if (self._npc.hand:count() <= 0) then
		-- uh oh
		self:_status(); -- This should fix it? In theory this won't ever be needed anyways
	end

	-- Find next valid rankID (if the current one isn't valid)
	while (not self._npc.hand:hasAny(rankID)) do
		rankID = (rankID + 1) % #Card.RANKS;
	end

	local foundCount = self._npc.hand:fishAny(self._player.hand, rankID);
	if (foundCount > 0) then
		self._outText.npcAskResult = self._npc.char:GetCleanName() .. " found " .. foundCount .. " " .. Card.RANK_FULL_NAMES[rankID+1] .. "s ";
		if (self._npc.hand:findRemoveSet(rankID)) then
			self._outText.npcFindSet = self._npc.char:GetCleanName() .. " found all the " .. Card.RANK_FULL_NAMES[rankID+1] .. "s! ";
		end
	else
		self._outText.npcAskResult = self._npc.char:GetCleanName() .. " didn't find any " .. Card.RANK_FULL_NAMES[rankID+1] .. "... Go fish! ";
		self:_npcGoFish();
	end

	self:_status();
end

function GoFishInstance:_npcGoFish()
	local card = self:npcFish();
	if (not card) then
		card = self:defaultFish();
	end
	self._npc.hand:addTop(card);
end
function GoFishInstance:_playerGoFish()
	local card = self:playerFish();
	if (not card) then
		card = self:defaultFish();
	end
	self._player.hand:addTop(card);
end




-- Returns all due money to the player, both from winnings and remaining handin (if any)
function BlackjackInstance:Cashout()
	payClient(self._player.char, self._player.handin + self._player.due);
end