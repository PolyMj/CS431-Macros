-- Format for defining an object:
	-- function {CLASSNAME}(CONSTRUCTOR_PARAMETERS)
		-- Arithmetic, checks, calculations, etc.
		-- local instance {
			-- PARAM_1 = ...;
			-- PARAM_2 = ...;
			-- ...
			-- FUNC_1 = function(self, PARAMETERS) ... end;
		-- }
		-- return instance
	-- end

-- Local instane is essentially a "box" of stuff that makes up everything in the class



function Obj(name)
	local instance = {
		name = name;
		
		toString = function(self)
			return "[" .. name .. "]";
		end
	}
	return instance
end

function List()
	local instance = {
		list = {};

		addObj = function(self, obj)
			table.insert(self.list, obj);
		end;
		
		toString = function(self)
			local string = "{:";
			for i, obj in pairs(self.list) do
				string = string .. " " .. obj:toString() .. " :";
			end
			return string .. "}"
		end;
	}
	return instance
end


local myList = List();
while true do
	io.write("LocalTest> ")
	local userInput = io.read()
	if (userInput == "q") then break end;

	if (userInput == "p") then
		print(myList:toString());
	else
		myList:addObj(Obj(userInput));
	end
end