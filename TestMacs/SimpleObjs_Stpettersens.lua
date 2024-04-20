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

-- 	 Instead of storing a million condition variables to determine where the player's message
-- needs to be sent to, we can have a single global varaible (stage) that holds a parser
-- function that user input will always be sent to. 

-- 	 E.g. stage starts off at a default 
-- "what would you like to do" type of thing, then if the user wants to buy something, stage
-- is updated to a function that will expect user input to enter what they want to buy, then
-- to something that looks for how much they want to buy, and so on.

local stage = nil;

-- Group of parsers and related attributes
-- Groups will make it much easier to look through code, epsecially since VSCode will allow you to collapse it
local parser_group = {}; -- NOTE: Need to define an empty set before the actual definition because scope and shit
parser_group = {
	-- Pointless function
	yells = 0;
	random = function(text)
		if (text == "s") then
			stage = objTesting;
			io.write("Sent to objTesting, say 'p' to print the current list > ");
			return;
		elseif (parser_group.yells == 0) then
			io.write("First time yelling at this wall for no reason, proud of you bub > ");
			parser_group.yells = parser_group.yells + 1;
		else
			io.write("You've yelled here " .. parser_group.yells .. " times > ");
			parser_group.yells = parser_group.yells + 1;
		end
	end;

	-- Echos whatever text it recieves
	mockingbird = function(text)
		if (text == "s") then
			stage = parser_group.random;
			io.write("Sent to parser_group.random > ");
			return;
		end
		io.write(text .. " > ");
	end;
};

-- Used for texting Lua OOP
function objTesting(text, a)
	if (text == "p") then
		print(myList:toString());
	elseif (text == "s") then
		stage = parser_group.mockingbird;
		io.write("Sent to parser_group.mockingbird > ");
		return;
	else
		myList:addObj(Obj.new(text));
	end
	io.write("Say 'p' to print the current list or anything else to add a new object > ");
end



-- MAIN CODE
stage = objTesting;
print("ALL: Use 's' to switch between parsers");
io.write("Sent to objTesting, say 'p' to print the current list or anything else to add a new object > ");

-- Main loop
while true do
	local userInput = io.read()
	if (userInput == "q") then break end;

	if (stage) then
		stage(userInput);
	else
		print("No parser function, not sure what to do here...");
		break;
	end
end