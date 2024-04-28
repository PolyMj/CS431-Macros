-- Npc for playing "Blackjack"
package.path = package.path .. ";/home/eqemu/server/quests/?.lua";
require("Blackjack");

-- Custom dealer AI to get one random card and one face card
function BlackjackInstance:bestOfThree()
    for i=1,2 do
        local best_card
        local best_card_index
        for i=1,3 do
            local card = self.deck:peekRandom();
            -- If card is better than best_card
            if (not best_card or (card and (card:isAce() or card:value() > best_card:value()))) then
                best_card = card;
                best_card_index = i;
            end
        end
        
        -- Add the best card from the selection of 3
        if (best_card) then
            self.dealer.hand:addTop(best_card);
            table.remove(self.deck.cards, best_card_index);
        else
            -- Get random card
            self._dealer.hand:addTop(deck:drawRandom());
        end
    end
end



function event_say(e)
    local npc = e.self;
    local client = e.other;

    -- If a game is ongoing, pass all messages to game:go()
    if (game) then
        game:go(e.message);
        
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
        e.self:Say("Well, well, well, what do we have here? Another traveler passing through? You look like someone who enjoys a bit of excitement, am I right? Are you ready to play a [game] of chance?");
    
    elseif e.message:findi("game") then
        local id = e.other:AccountID();
        local bucket = "-gambling-games-finnegan"
        local bucketkey = id .. bucket;
        if (eq.get_data(bucketkey) == "1") then
            e.self:Say("You've already beat me, but we can [play] another round if you want.[reset]");
        else
            e.self:Say("Just a standard game of blackjack, you wanna [play]? I'll make it cheap, minimum 2 platinum per hand sound good?");
        end
    
    elseif e.message:findi("play") then
        game = BlackjackInstance.new(npc, client, 10000); -- 10 plat requirement
        if (game) then
            game.dealerAI = BlackjackInstance.bestOfThree;
            game:go(nil, client);
        end

    elseif e.message:findi("reset") then
        -- resets data bucket for testing
        local id = e.other:AccountID();
        local bucket = "-gambling-games-finnegan"
        local bucketkey = id .. bucket;
        eq.delete_data(bucketkey);
        e.self:Say("bucket deleted" .. bucketkey);
    end
end


function winner(e)
    -- get name of bucket
    local id = e.other:AccountID();
    local bucket = "-gambling-games-finnegan"
    local bucketkey = id .. bucket;
    local value = "1";
    -- winner dialogue
    e.self:Say("Hmph, don't get too cocky. Luck's a fickle thing, it'll turn on you soon enough.[reset]");
    e.self:Say("testing" .. bucketkey .. value);
    -- set winner status (1)
    eq.set_data(bucketkey, value);
    local testvalue = eq.get_data(bucketkey);
    e.self:Say("the bucket value is " .. testvalue);
end


function loser(e)
    e.self:Say("Look's like Lady Luck's on my side tonight, better light next time");
end


function event_trade(e)
	local trade = e.trade;
	local npc = e.self;
	local client = e.other;

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