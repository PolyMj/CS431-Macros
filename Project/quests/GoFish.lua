package.path = package.path .. ";/home/eqemu/server/quests/?.lua";
require("Cards");

GOFISH_FLAG = "-GoFish";

math.randomseed(os.time())

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
		optionsPrompt = "";
		gameOverStatus = nil;
	};

	self.RETURNS = {
		LOSE = 0;
		DRAW = 1;
		WIN = 2;
	};

	self.playerFish = GoFishInstance.defaultPlayerFish;
	self.npcFish = GoFishInstance.defaultNpcFish;

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

-- Default fish mechanics for NPC and player
function GoFishInstance:defaultNpcFish()
	self._npc.hand:addTop(self.deck:drawRandom());
end
function GoFishInstance:defaultPlayerFish()
	self._player.hand:addTop(self.deck:drawRandom());
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

function GoFishInstance:go(text, client)
	-- Checks if passed in client matches current. If not, save other game and create new game
	if (client and self._player.char:AccountID() ~= client:AccountID()) then
		self:exit();
		self:_fromBucket(self._npc.char, client);
		return;
	end

	if (text and text == "Exit" and #self._player.hands > 0) then
		self._npc.char:Say("Game saved");
		self:exit();
		return;
	end

	self:_STAGE(text);
end

function GoFishInstance:_initializeGame()
	-- Check / request payment
	if (self._player.handin < self.required_payment) then
		self._dealer.char:Say(
			"You'll need to pay before you play (" .. 
			self._player.handin .. "/" .. self.required_payment .. ")"
		);
		self.requesting_payment = true;
		self._STAGE = GoFishInstance._initializeGame;
		return;
	end

	-- Initialize deck
	self.deck = Deck.new(self.deck_count, 1);
	self._npc.char:Say("" .. self.deck_count);

	-- Initialize hands
	self._npc.hand = Deck.new(0,0);
	self._player.hand = Deck.new(0,0);

	-- Fish out the cards for player and npc
	for i=1, self.initial_card_count do
		self:npcFish();
		self:playerFish();
	end

	self._npc.char:Say("End fishing");

	-- Set bet and reset player handin
	self._player.bet = self._player.handin;
	self._player.handin = 0;
	self:_status();
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
	
	self:displayGame();

end

function GoFishInstance:displayGame()
	local dia_string = "{title: Go Fish with " .. self._npc.char:GetCleanName() .. "} ";

	-- DiaWinds really hate single custom buttons ig
	dia_string = dia_string .. "{button_one: Exit} {button_two: Exit} ";

	-- Window type
	dia_string = dia_string .. "wintype:1 ";

	-- NPC's hand
	dia_string = dia_string .. "{linebreak} {y} " .. self._npc.char:GetCleanName() .. " has around " ..
		(math.random(1, self._npc.hand:count()) + math.random(1, self._npc.hand:count())) ..
		" cards ~ ";

	-- Player's hand
	dia_string = dia_string .. "{linebreak} {lb} Your cards";
	for i,c in pairs(self._player.hand.cards) do
		dia_string = dia_string .. " {bullet} " .. c:toFullString();
	end
	dia_string = dia_string .. " ~ ";

	-- If game over
	if (self._outText.gameOverStatus ~= "") then
		dia_string = dia_string .. "{linebreak} {r} " .. (self._outText.gameOverStatus or "GAME OVER") .. " ";
	-- Else display error dialogue
	else
		if (#self.outText.errorDialogue > 0) then
			dia_string = dia_string .. "{linebreak} {r}";
			for i,v in pairs(self.outText.errorDialogue) do
				dia_string = dia_string .. " {bullet} " .. v
			end
			dia_string = dia_string .. " ~ ";
		end
		self.outText.errorDialogue = {};
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


function GoFishInstance:_turn()
	return;
end