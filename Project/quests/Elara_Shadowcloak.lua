-- Npc for playing ""

function event_say(e)
    if e.message:findi("hail") then
        -- local bucketkey = e.other:GetID();
        e.self:Say("Wanna play a game?" .. e.other:GetID());
    end
end

function event_item(e)
    -- fill out if needed
end

function event_exit(e)
    -- for when the player leaves the area
end