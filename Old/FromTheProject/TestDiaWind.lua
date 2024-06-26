local npc;
local client;

-- Place all importable lua files in /server/quests/, then add this to the path:
package.path = package.path .. ";/home/eqemu/server/quests/?.lua";
require("Obj");

-- Button presses come through event_say
-- Dialogue windows are set up using this weird-ass markdown formatting
-- Don't change windtype from 1, can break things and I honestly don't know what the deal is

local object = Obj.new("Roberto");

function event_say(e)
	npc = e.self;
	client = e.other;

	npc:Say("You pressed a button or said something idk");

	client:DialogueWindow(
		"{title: Window Title} " .. -- MUST USE EXTRA SPACE BETWEEN ITEMS
		"{button_one: Button 1} " ..-- MUST SPACES, NOT NEWLINES
		"{button_two: Button 2} " ..
		"wintype:1 " ..
		"Some dialogue"
	); -- [clickable text] WILL BREAK THE BUTTONS IN STRANGE WAYS
	   -- USE A SEPARATE npc:Say() TO DISPLAY EXTRA RESPONSES

	npc:Say(e.message);
	npc:Say("Imported object: " .. object:toString());
end