package.path = package.path .. ";/home/eqemu/server/quests/?.lua";
require("Cards");

GOFISH_FLAG = "-GoFish";
WINNINGS_FLAG = "-GFWinnings";
WAGERS_FLAG = "-GFWagers";

math.randomseed(os.time())


-- Adds all matching rank cards from otherDeck to self, and returns the number of cards found
function Deck:fishAny(otherDeck, rankID)
	local count = 0;
	local i = 1;
	while (i <= #otherDeck.cards) do
		if (otherDeck.cards[i]:rankID() == rankID) then
			local card = otherDeck.cards[i];
			table.remove(otherDeck.cards, i);
			self:addSort(card);
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
	local unfound = {0, 1, 2, 3};
	local base_id = rankID * 4;
	local found_indices = {};
	for ci,card in pairs(self.cards) do
		-- If the rank id matches
		if (card:rankID() == rankID) then
			-- Check if it matches an unfound suite
			local ui = 1;
			while (ui <= #unfound) do
				local id = unfound[ui] + base_id;
				if (id == card.id) then
					table.insert(found_indices, ci);
					table.remove(unfound, ui)
				else
					ui = ui + 1;
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


function addToBucket(client, FLAG, addend)
	local data = tonumber(client:GetBucket(FLAG));
	local data = data or 0;
	local data = data + addend;
	client:SetBucket(FLAG, tostring(data));
end


GoFishInstance = {
	STATUS = {
		UNSTARTED = -2;
		FORFEIT = -1;
		ONGOING = 0;
		LOSE = 1;
		DRAW = 2;
		WIN = 3;
	};
};
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
		hand = nil;
		foundSets = 0;
	};

	self._npc = {
		char = npc;
		hand = nil;
		foundSets = 0;
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

	self.gameOverStatus = GoFishInstance.STATUS.UNSTARTED;

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


function GoFishInstance:getFlagSuffix()
	return self._npc.char:GetCleanName() .. self._player.char:AccountID();
end


-- Adds amount_copper to the player's handin total
function GoFishInstance:handin(amount_copper, client)
	if (client and self._player.char:AccountID() ~= client:AccountID()) then
		self:exit();
		self:_fromBucket(self._dealer.char, client);
	end

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

function GoFishInstance:_initializeGame()
	-- Try to initialize from a databucket first
	self:_fromBucket(self._npc.char, self._player.char);
	if (self.gameOverStatus == GoFishInstance.STATUS.ONGOING) then
		self:_status();
		return;
	end
	
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
	self.gameOverStatus = GoFishInstance.STATUS.ONGOING;
	self._npc.foundSets = 0;
	self._player.foundSets = 0;

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
	addToBucket(self._player.char, WAGERS_FLAG .. self:getFlagSuffix(), self._player.bet);
	self._player.handin = 0;
	self:_status();
end

function GoFishInstance:displayGame()
	local dia_string = "{title: Go Fish with " .. self._npc.char:GetCleanName() .. "} ";

	dia_string = dia_string .. "{button_one: Exit} {button_two: Forfeit} ";

	-- Window type
	dia_string = dia_string .. "wintype:1 ";

	-- Got game over --> display error dialogue
	if (self.gameOverStatus == GoFishInstance.STATUS.ONGOING and #self._outText.errorDialogue > 0) then
		dia_string = dia_string .. "{linebreak} {r}";
		for i,v in pairs(self._outText.errorDialogue) do
			dia_string = dia_string .. " {bullet} " .. v
		end
		dia_string = dia_string .. " ~ ";
	end
	self._outText.errorDialogue = {};

	-- Deck
	if (self.deck:count() > 0) then
		dia_string = dia_string .. "{linebreak} The deck has around " ..
			(math.random(1, self.deck:count()) + math.random(1, self.deck:count())) ..
			" cards, ~ ";
	else
		dia_string = dia_string .. "{linebreak} The deck is empty, ";
	end

	-- NPC's hand
	if (self._npc.hand:count() > 0) then
		dia_string = dia_string .. " {y} " .. self._npc.char:GetCleanName() .. " has around " ..
			(math.random(1, self._npc.hand:count()) + math.random(1, self._npc.hand:count())) ..
			" cards ~ ";
	else
		dia_string = dia_string .. " {y} " .. self._npc.char:GetCleanName() .. "'s hand is empty ~ ";
	end

	-- Sets
	dia_string = dia_string .. "{linebreak} {g} You've found " .. self._player.foundSets .. " sets ~ || {r}" ..
		self._npc.char:GetCleanName() .. " has found " .. self._npc.foundSets .. " sets ~ ";

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
	-- If player found a set
	if (self._outText.playerFindSet) then
		dia_string = dia_string .. "{linebreak} {g} " .. self._outText.playerFindSet .. " ~ ";
	end
	self._outText.playerFindSet = nil;

	-- Result of npc's ask
	if (self._outText.npcAskResult) then
		dia_string = dia_string .. "{linebreak} {r} " .. self._outText.npcAskResult .. " ~ ";
	end
	self._outText.npcAskResult = nil;
	-- If npc found a set
	if (self._outText.npcFindSet) then
		dia_string = dia_string .. "{linebreak} {r} " .. self._outText.npcFindSet .. " ~ ";
	end
	self._outText.npcFindSet = nil;

	-- If game over
	if (self.gameOverStatus ~= GoFishInstance.STATUS.ONGOING) then
		dia_string = dia_string .. "{linebreak} {r} ";
		-- Get exact game conclusion
		if (self.gameOverStatus == GoFishInstance.STATUS.LOSE) then
			dia_string = dia_string .. "You lose!";
		elseif (self.gameOverStatus == GoFishInstance.STATUS.DRAW) then
			dia_string = dia_string .. "It's a draw!";
		elseif (self.gameOverStatus == GoFishInstance.STATUS.WIN) then
			dia_string = dia_string .. "You win!";
		else
			dia_string = dia_string .. "GAME OVER"; -- Should never happen, here just in case
		end
		dia_string = dia_string .. " ~ ";
	end

	-- Bet
	if (self._player.bet > 0) then
		dia_string = dia_string .. "{linebreak} {gold} Bet is " .. self._player.bet .. "c ~ ";
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

function GoFishInstance:exit()
	self:Cashout();
	local FLAG = GOFISH_FLAG .. self._npc.char:GetCleanName() .. self._player.char:AccountID();

	local data = "";

	-- Get player's bet
	data = data .. (tostring(self._player.bet) or "0") .. " ";
	-- Get player's hand
	data = data .. self._player.hand:to64() .. " ";
	-- Get player's found sets
	data = data .. (tostring(self._player.foundSets) or "0") .. " ";
	-- Get npc's hand
	data = data .. self._npc.hand:to64() .. " ";
	-- Get npc's found sets
	data = data .. (tostring(self._npc.foundSets) or "0") .. " ";
	-- Get deck
	data = data .. self.deck:to64();

	self._player.char:SetBucket(FLAG, data);

	self._STAGE = GoFishInstance._initializeGame;
end

function GoFishInstance:_deleteBucket()
	local FLAG = GOFISH_FLAG .. self._npc.char:GetCleanName() .. self._player.char:AccountID();
	self:Cashout();
	self._player.char:DeleteBucket(FLAG);
end

function GoFishInstance:_fromBucket(npc, client)
	local FLAG = GOFISH_FLAG .. npc:GetCleanName() .. client:AccountID();
	local data = client:GetBucket(FLAG);

	-- Set new client
	self._player.char = client;

	-- If data bucket load was successful, play
	if (self:_parseBucket(data)) then
		self.gameOverStatus = GoFishInstance.STATUS.ONGOING;
		self._STAGE = GoFishInstance._status;
	-- Otherwise, new game
	else
		npc:Say("No valid data found, initializing new game...");
		self._STAGE = GoFishInstance._initializeGame;
	end

	client:DeleteBucket(FLAG);
end

function GoFishInstance:_parseBucket(data)
	if (#data < 5) then return false end

	local chunks = {};

	-- Separated by whitespace
	for chunk in data:gmatch("%S+") do
		table.insert(chunks, chunk);
	end
	if (#chunks ~= 6) then
		self._npc.char:Say("Incorrect number of data chunks");
		return false;
	end

	self._player.bet = tonumber(chunks[1]);

	self._player.hand = Deck.from64(chunks[2]);

	self._player.foundSets = tonumber(chunks[3]);

	self._npc.hand = Deck.from64(chunks[4]);

	self._npc.foundSets = tonumber(chunks[5]);

	self.deck = Deck.from64(chunks[6]);

	if (self._player.bet and self._player.hand and self._npc.hand and self._player.foundSets and self._npc.foundSets and self.deck) then
		return true;
	else
		self._npc.char:Say("Data couldn't be initialized");
		return false
	end
end


-- Gameplay

function GoFishInstance:go(text, client)
	-- Checks if passed in client matches current. If not, save other game and create new game
	if (client and self._player.char:AccountID() ~= client:AccountID()) then
		self:exit();
		self:_fromBucket(self._npc.char, client);
		return;
	end

	if (text and text == "Forfeit") then
		self._STAGE = GoFishInstance._initializeGame;
		self:_deleteBucket();
		self.gameOverStatus = GoFishInstance.STATUS.FORFEIT;
		return;
	end

	if (text and text == "Exit") then
		self._npc.char:Say("Game saved");
		self:exit();
		return;
	end

	self:_STAGE(text);
end


function GoFishInstance:_status()
	-- Check win/lose/draw
	if (self._player.hand:count() <= 0) or (self._npc.hand:count() <= 0) or (self.deck:count() <= 0) then
		if (self._player.foundSets > self._npc.foundSets) then
			self.gameOverStatus = GoFishInstance.STATUS.WIN;
		elseif (self._player.foundSets == self._npc.foundSets) then
			self.gameOverStatus = GoFishInstance.STATUS.DRAW;
		else
			self.gameOverStatus = GoFishInstance.STATUS.LOSE;
		end
	end
	
	if (self.gameOverStatus == GoFishInstance.STATUS.ONGOING) then
		self:_turn();
	else
		self:displayGame();
		self:Cashout();
		self._STAGE = GoFishInstance.displayGame;
	end
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
		table.insert(self._outText.errorDialogue, "Sorry, don't know what rank that is");
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
			self._player.foundSets = self._player.foundSets + 1;
		end
	else
		self._outText.playerAskResult = "You didn't find any " .. Card.RANK_FULL_NAMES[rankID+1] .. "s... Go fish! ";
		self:_playerGoFish();
	end

	-- If npc still has cards
	if (self._npc.hand:count() > 0) then
		self:_npcsTurn();
	end

	self:_status();
end


function GoFishInstance:_npcsTurn()
	local rankID = self:npcAsk();

	if (self._npc.hand:count() <= 0) then
		-- uh oh
		self:_status(); -- This should fix it? In theory this won't ever be needed anyways
	end

	-- Find next valid rankID (if the current one isn't valid)
	local tries = 100;
	while (not self._npc.hand:hasAny(rankID) and tries > 0) do
		rankID = (rankID + 1) % #Card.RANKS;
		tries = tries - 1;
	end

	local foundCount = self._npc.hand:fishAny(self._player.hand, rankID);
	if (foundCount > 0) then
		self._outText.npcAskResult = self._npc.char:GetCleanName() .. " found " .. foundCount .. " " .. Card.RANK_FULL_NAMES[rankID+1] .. "s ";
		if (self._npc.hand:findRemoveSet(rankID)) then
			self._outText.npcFindSet = self._npc.char:GetCleanName() .. " found all the " .. Card.RANK_FULL_NAMES[rankID+1] .. "s! ";
			self._npc.foundSets = self._npc.foundSets + 1;
		end
	else
		self._outText.npcAskResult = self._npc.char:GetCleanName() .. " didn't find any " .. Card.RANK_FULL_NAMES[rankID+1] .. "s... Go fish! ";
		self:_npcGoFish();
	end
end

function GoFishInstance:_npcGoFish()
	local card = self:npcFish();
	if (not card) then
		card = self:defaultFish();
	end
	self._npc.hand:addSort(card);

	local rankID = card:rankID();
	if (self._npc.hand:findRemoveSet(rankID)) then
		self._outText.npcFindSet = self._npc.char:GetCleanName() .. " found all the " .. Card.RANK_FULL_NAMES[rankID+1] .. "s! ";
		self._npc.foundSets = self._npc.foundSets + 1;
	end
end
function GoFishInstance:_playerGoFish()
	local card = self:playerFish();
	if (not card) then
		card = self:defaultFish();
	end
	self._player.hand:addSort(card);

	local rankID = card:rankID();
	if (self._player.hand:findRemoveSet(rankID)) then
		self._outText.playerFindSet = "You found all the " .. Card.RANK_FULL_NAMES[rankID+1] .. "s! ";
		self._player.foundSets = self._player.foundSets + 1;
	end
end




-- Returns all due money to the player, both from winnings and remaining handin (if any)
function GoFishInstance:Cashout()
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