-- Npc for playing ""

function event_say(e)
    if e.message:findi("hail") then
        e.self:Say("How about a little [game] of chance? I've got something that'll get your heart pumping faster than a racehorse on derby day[reset]");
    elseif e.message:findi("game") then
        local id = e.other:GetID();
        local bucket = "-gambling-games-grimgar"
        local bucketkey = id .. bucket;
        if (eq.get_data(bucketkey) == "1") then
            e.self:Say("You've already beat me, but we can [play] another round if you want.[reset]");
        else
            -- Explain the game rules here?
            e.self:Say("[play]");
        end
    elseif e.message:findi("play") then
        -- place game here?
        -- testing jump to winner
        e.self:Say("[winner]");
    elseif e.message:findi("winner") then
        -- get name of bucket
        local id = e.other:GetID();
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
    elseif e.message:findi("reset") then
        -- resets data bucket for testing
        local id = e.other:GetID();
        local bucket = "-gambling-games-grimgar"
        local bucketkey = id .. bucket;
        eq.delete_data(bucketkey);
        e.self:Say("bucket deleted" .. bucketkey);
    end
end

function event_item(e)
    -- fill out if needed
end

function event_exit(e)
    -- for when the player leaves the area
end