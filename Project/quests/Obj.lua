
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