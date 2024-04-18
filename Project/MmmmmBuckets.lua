local base64_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

-- Base64 encoding function (Totally not from ChatGPT)
function tob64(num)
    local result = ""
    while num > 0 do
        local index = num % 64 + 1
        result = string.sub(base64_chars, index, index) .. result
        num = math.floor(num / 64)
    end
    return result
end

-- Base64 decoding function (Also not at all copied from ChatGPT)
function fromb64(str)
    local num = 0
    for i = 1, #str do
        local char = string.sub(str, i, i)
        local index = string.find(base64_chars, char)
        num = num * 64 + (index - 1)
    end
    return num
end




PlayingCard = { 
	id = 0, 
	TYPES = {"S", "H", "D", "C"},
	VALUES = {"jo", "2", "3", "4", "5", "6", "7", "8", "9", "10", "Ja", "Q", "K", "A", "+", "-" }
};

function PlayingCard:new (obj, id)
	-- Setup metatable (needed for Lua objects I guess?)
	obj = obj or {};
	setmetatable(obj, self);
	self.__index = self;

	if (0 <= id and id < 64) then
		self.id = id;
	end

	return obj;
end

function PlayingCard:typeNum()
	return math.floor(self.id / 16);
end
function PlayingCard:typeStr()
	return self.TYPES[self:typeNum()+1];
end
function PlayingCard:valNum()
	return (self.id % 16);
end
function PlayingCard:valStr()
	return self.VALUES[self:valNum()+1];
end

function PlayingCard:toString()
	if (self.id < 0 or self.id >= 64) then
		return "{Invalid}";
	end

	return "[" .. self:valStr() .. " of " .. self:typeStr() .. "]";
end

function PlayingCard:new64(obj, chr)
	local data = fromb64(chr);
	return PlayingCard:new(obj, tonumber(data));
end

function PlayingCard:to64()
	return tob64(self.id);
end


-- Not sure how this works, oh well
function event_spawn(e)
	local x = e.self:GetX();
	local y = e.self:GetY();
	local z = e.self:GetZ();
	eq.set_proximity((x-50), (x+50), (y-50), (y+50), (z-50), (z+50));
end

-- Same with this
function event_proximity_say(e)
	e.self:Say("Hello there");
end


local myCard = nil;

function event_say(e)
	local client = e.other;
	local FLAG = client:AccountID() .. "-MmmmmBuckets";

	if (e.message:findi("Hail")) then
		

	elseif (e.message:findi("Pull Card")) then
		myCard = PlayingCard:new(nil, math.random(0, 63));
	
	elseif (e.message:findi("Print Card")) then
		if (myCard) then
			e.self:Say(myCard:toString());
		else
			e.self:Say("You don't have a card yet");
		end
	
	elseif (e.message:findi("Save Card")) then
		if (myCard) then
			client:SetBucket(FLAG, myCard:to64());
		else
			e.self:Say("You don't have a card yet");
		end
	
	elseif (e.message:findi("Load Card")) then
		local bucket_data = client:GetBucket(FLAG);
		if (bucket_data == "") then
			e.self:Say("You haven't saved a card yet");
		else
			myCard = PlayingCard:new64(nil, bucket_data);
			e.self:Say("Your card is " .. myCard:toString());
		end
	end

	-- Just printing this every time for now
	e.self:Say("[Pull Card] [Print Card] [Save Card] [Load Card] or set");
end