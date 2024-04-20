-- Format:
	-- CLASS_NAME = {};
	-- CLASS_NAME.__index = CLASSNAME;
	-- function CLASS_NAME.[constructor](CONSTRUCTOR_PARAMETERS)
		-- local self = setmetatable({}, CLASS_NAME);
		-- self.ATTR = ATTR;
		-- ...
		-- return self;
	
	-- function CLASS_NAME:[MEMBER_FUNC_NAME](PARAMETERS)
		-- self.ATTR = ...;
	-- end

-- START OF OBJ CLASS --
Obj = {};
Obj.__index = Obj;
function Obj.new(name)
	local self = setmetatable({}, Obj);

	self.name = name;

	return self;
end

function Obj:toString()
	return "[" .. self.name .. "]";
end
-- END OF OBJ CLASS -- 


-- START OF LIST CLASS --
List = {};
List.__index = List;
function List.new()
	local self = setmetatable({}, List);

	self.list = {};

	return self;
end

function List:addObj(obj)
	table.insert(self.list, obj);
end

function List:toString()
	local string = "{:";
	for i, obj in pairs(self.list) do
		string = string .. " " .. obj:toString() .. " :";
	end
	return string .. "}"
end
-- END OF LIST CLASS


local myList = List.new();


-- START OF PARSING STUFF --
local stage = nil;

-- Group of parsers and related attributes
local parser_group = {}; -- NOTE: Need to define an empty set before the actual definition because scope and shit
parser_group = {
	-- Pointless function
	yells = 0;
	random = function(text)
		if (text == "s") then
			stage = parser_group.mockingbird;
		elseif (parser_group.yells == 0) then
			print("First time yelling at this wall for no reason, proud of you bub");
			parser_group.yells = parser_group.yells + 1;
		else
			print("You've yelled here " .. parser_group.yells .. " times");
			parser_group.yells = parser_group.yells + 1;
		end
	end;

	-- Echos whatever text it recieves
	mockingbird = function(text)
		print(text);
		if (text == "s") then
			stage = parser_group.random;
		end
	end;
};

-- Used for texting Lua OOP
function objTesting(text, a)
	if (text == "p") then
		print(myList:toString());
	elseif (text == "s") then
		stage = parser_group.mockingbird;
	else
		myList:addObj(Obj.new(text));
	end
end



-- MAIN CODE
stage = objTesting;

-- Main loop
while true do
	io.write("LocalTest > ")
	local userInput = io.read()
	if (userInput == "q") then break end;

	if (stage) then
		stage(userInput);
	else
		print("No parser function, not sure what to do here...");
	end
end