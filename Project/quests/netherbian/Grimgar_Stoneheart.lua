-- Npc for playing ""
package.path = package.path .. ";/home/eqemu/server/quests/?.lua";
require("Blackjack");


-- Custom dealer AI to get one random card and one face card
function BlackjackInstance:hiddenFace()
    -- Get random card
    self._dealer.hand:addTop(self.deck:drawRandom());

    for i,card in pairs(self.deck.cards) do
        if (card:rankID() == 2) then
            self._dealer.hand:addTop(card);
            table.remove(self.deck.cards, i);
            return;
        end
    end
    -- If no ace found, get another random card
    self._dealer.hand:addTop(self.deck:drawRandom());
end



local game;

function event_say(e)
    local npc = e.self;
    local client = e.other;

    -- If a game is ongoing, pass all messages to game:go()
    if (game) then
        game:go(e.message);
        npc:Say("Status = " .. game.status);
        
        if (game.status == BlackjackInstance.STATUS.FINISHED) then
            if (game._player.handsWon > game._player.handsLost) then
                winner(e)
            else    
                loser(e);
            end
            game = nil;
        end
    end

    if e.message:findi("hail") then
        if (game) then 
            game:exit() 
            game = nil;
        end
        e.self:Say("How about a little [game] of chance? I've got something that'll get your heart pumping faster than a racehorse on derby day[reset]");
    end

    
    if e.message:findi("game") then
        local id = e.other:AccountID();
        local bucket = "-gambling-games-grimgar"
        local bucketkey = id .. bucket;
        if (eq.get_data(bucketkey) == "1") then
            e.self:Say("You've already beat me, but we can [play] another round if you want.[reset]");
        else
            -- Explain the game rules here?
            e.self:Say("Just a standard game of blackjack, you wanna [play]? You'll need to pay me of course, say minimum of 10 platinum per hand?");
        end
    
    elseif e.message:findi("play") then
        game = BlackjackInstance.new(npc, client, 10000); -- 10 plat requirement
        if (game) then
            game:go(nil, client);
        end

    elseif e.message:findi("reset") then
        -- resets data bucket for testing
        local id = e.other:GetID();
        local bucket = "-gambling-games-grimgar"
        local bucketkey = id .. bucket;
        eq.delete_data(bucketkey);
        e.self:Say("bucket deleted" .. bucketkey);
    end
end

function winner(e)
    -- get name of bucket
    local id = e.other:AccountID();
    local bucket = "-gambling-games-grimgar"
    local bucketkey = id .. bucket;
    local value = "1";
    -- winner dialogue
    e.self:Say("No hard feelings? Ha! Don't make me laugh. Now get out of here before I change my mind.[reset]");
    e.self:Say("testing" .. bucketkey .. value);
    -- set winner status (1)
    eq.set_data(bucketkey, value);
    local testvalue = eq.get_data(bucketkey);
    e.self:Say("the bucket value is " .. testvalue);
end


function loser(e)
    e.self:Say("No beginner's luck for you, eh? I'm sure you'll do better next time...");
end

function event_trade(e)
	local trade = e.trade;
	npc = e.self;
	client = e.other;

	local money = trade.copper + 10*(trade.silver + 10*(trade.gold + 10*(trade.platinum)));
	if (money) then
		if (game) then
			game:handin(money);
			game:go();
		else
			client:AddMoneyToPP(trade.copper, trade.silver, trade.gold, trade.platinum, true);
		end
	end
end

function event_exit(e)
    -- for when the player leaves the area
    if (game) then
        game:exit();
        game = nil;
    end
end