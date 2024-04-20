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

-- MAIN CODE
local myList = List.new();
while true do
	io.write("LocalTest> ")
	local userInput = io.read()
	if (userInput == "q") then break end;

	if (userInput == "p") then
		print(myList:toString());
	else
		myList:addObj(Obj.new(userInput));
	end
end