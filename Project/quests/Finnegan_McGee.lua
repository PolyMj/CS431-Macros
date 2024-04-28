-- Npc for playing ""

function event_say(e)
    if e.message:findi("hail") then
        -- local bucketkey = e.other:GetID();
        e.self:Say("Well, well, well, what do we have here? Another traveler passing through? You look like someone who enjoys a bit of excitement, am I right? Are you ready to play a [game] of chance?");
    elseif e.message:findi("game") then
        local id = e.other:GetID();
        local bucket = "-gambling-games-finnegan"
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
    elseif e.message:findi("reset") then
        -- resets data bucket for testing
        local id = e.other:GetID();
        local bucket = "-gambling-games-finnegan"
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