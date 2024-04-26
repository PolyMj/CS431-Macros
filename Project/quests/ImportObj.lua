-- This makes lua search through the parent directory for other lua files to import/require
-- You can go two directories using ";../../?.lua", and keep going as needed.
-- This means we can place a Cards class "in server/quests/", and import from whatever zones we may need
package.path = package.path .. ";../?.lua";
require("Obj");

local myObj = Obj.new("Bob");

print(myObj:toString());