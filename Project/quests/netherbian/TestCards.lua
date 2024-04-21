package.path = package.path .. ";../?.lua";
require("Cards");
local STAGE = nil;


local deck = Deck.new(1);
if (deck) then
	print(deck:toString());
else
	print("Nil recieved");
end