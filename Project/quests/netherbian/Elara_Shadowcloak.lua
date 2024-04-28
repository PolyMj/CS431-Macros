-- 'Final boss' Npc for playing "Go Fish"
package.path = package.path .. ";/home/eqemu/server/quests/?.lua";
require("GoFish");


function GoFishInstance:peekPlayersHand()
    local id = self._player.hand:peekRandom():rankID();
    self._npc.char:Say("Looking for id = " .. id);
    return id;
end

function GoFishInstance:fishForSet()
    for i,ncard in pairs(self._npc.hand.cards) do
        for k,dcard in pairs(self.deck.cards) do
            if (dcard:rankID() == ncard:rankID()) then
                local card = dcard;
                if (self.deck:removeIndex(k)) then
                    return card;
                end
            end
        end
    end
end



function event_say(e)
    local npc = e.self;
    local client = e.other;

    -- If a game is ongoing, pass all messages to game:go()
    if (game) then
        game:go(e.message);

        if (game.gameOverStatus == GoFishInstance.STATUS.WIN) then
            winner(e);
            game = nil;
        elseif (game.gameOverStatus == GoFishInstance.STATUS.LOSE) then
            loser(e);
            game = nil;
        elseif (game.gameOverStatus == GoFishInstance.STATUS.DRAW) then
            draw(e);
            game = nil;
        end
        return;
    end


    if e.message:findi("hail") then
        if (game) then 
            game:exit() 
            game = nil;
        end
        local bucket_key = e.other:AccountID() .. "-the-gamblers-reckoning-finale";
        local bucketvalue = eq.get_data(bucket_key);
        -- check if quest is already complete
        if (bucketvalue == "1") then
            e.self:Say("let me make one thing crystal clear: I never want to see your face in my den again. You're nothing but a sore loser, and I have no time for losers. Now get out of here before I decide to make an example out of you.[reset]");
        else
            e.self:Say("Ah, another eager soul looking to test their luck, eh? Welcome to the den of the daring, the lair of the lucky, and the sanctum of the sleazy. I'm Elara, the queen of this little domain. What [brings you here], hmm");
        end
       
    elseif e.message:findi("brings you here") then
        -- TODO: insert game name here
        e.self:Say("A pendant? Oh yes, I've seen it. Of course, if you want to know more you will have to beat me in a [game] of (game name here)");
    
    elseif e.message:findi("game") then
        -- First get the completion status of the other games
        local id = e.other:AccountID();
        local bucket1 = "-gambling-games-grimgar";
        local bucket2 = "-gambling-games-finnegan";
        local grimId = id .. bucket1;
        local grimvalue = eq.get_data(grimId);
        local finnId = id .. bucket2;
        local finnvalue = eq.get_data(finnId);

        if (grimvalue == "1" and finnvalue == "1") then
            -- When both other games are complete
            e.self:Say("Impressive, I must say. I didn't think you had it in you. But while besting my associates is one thing, facing me is another entirely. Are you sure you're [ready] for this?");
        elseif (grimvalue == "1" and finnvalue ~= "1") then
            e.self:Say("Oh, feeling confident after besting Grimgar, are we? That's a bold move, my friend. But let's not get ahead of ourselves. You see, there's still one more obstacle standing between you and me. Go talk to Finnegan.");
        elseif (grimvalue ~= "1" and finnvalue == "1") then
            e.self:Say("Back so soon? I must say, I didn't expect to see you back here after your bout with Finnegan. He can be quite the handful, can't he? But let's not get ahead of ourselves. You see, Grimgar still stands in your way. And trust me, he's not one to underestimate.");
        elseif (grimvalue ~= "1" and finnvalue ~= "1") then
            e.self:Say( "Let's not get ahead of ourselves. You see, to even earn the privilege of facing me, you must first prove yourself against my esteemed associates, [Grimgar and Finnegan].")
        else
            e.self:Say("something went wrong");
        end
    
    elseif e.message:findi("Grimgar and Finnegan") then
        e.self:Say("Just follow the scent of desperation and the clinking of coins, and you'll stumble upon them soon enough.");
    
    elseif e.message:findi("ready") then
        local id = e.other:AccountID();
        local bucket1 = "-gambling-games-grimgar";
        local bucket2 = "-gambling-games-finnegan";
        local grimId = id .. bucket1;
        local grimvalue = eq.get_data(grimId);
        local finnId = id .. bucket2;
        local finnvalue = eq.get_data(finnId);
        -- Just making sure in case the player just walked up and said "ready" for some strange reason
        if not (grimvalue == "1" and finnvalue == "1") then
            e.self:Say("You are not ready you fool, leave!");
            return;
        end

        game = GoFishInstance.new(npc, client, 10000); -- 10 plat requirement
        if (game) then
            game.npcFish = GoFishInstance.fishForSet; -- Try to add to npc's sets
            game.npcAsk = GoFishInstance.peekPlayersHand; -- Try to ask for card in player's hand
            game:go(nil, client);
        end
    
    elseif e.message:findi("reset") then
        local bucket_key = e.other:AccountID() .. "-the-gamblers-reckoning-finale";
        eq.delete_data(bucket_key);
    end
end


function winner(e)
    e.self:Say("Fine, take the stupid pendant. But don't think this is over. I'll be watching you, player. You may have won today, but in this world, fortunes can change in an instant.");
    e.other:SummonItem(36465);
    local bucket_key = e.other:AccountID() .. "-the-gamblers-reckoning-finale";
    local bucket_value = "1";
    eq.set_data(bucket_key, bucket_value);
end

function loser(e)
    e.self:Say("I suppose you truly weren't ready for such a high-caliber game. I'll have to ask my associates how they let such a fool best them.");
end

function draw(e)
    e.self:Say("Well well well, you're not half bad. However, beginners luck will not be enough.");
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