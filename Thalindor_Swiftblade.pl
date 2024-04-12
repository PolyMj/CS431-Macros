
# Takes an amount of money in copper and gives it back to the player in the largest coin values
sub give_change {
	my ($money) = @_;
	my $copp = $money % 10;
	$money = $money / 10;
	my $silv = $money % 10;
	$money = $money / 10;
	my $gold = $money % 10;
	$money = $money / 10;
	my $plat = $money;
	quest::givecash($copp, $silv, $gold, $plat);
}

# Takes in the amount of money given by the player, and the cost
	# If cost exceeds given, returns false and returns all money to player
	# If given meets or exceeds cost, returns true and returns any excess to player
	# Money is in total value (e.g. how much copper the sum of all currencies is worth)
sub buy_return {
	my ($given, $cost) = @_;
	# If not enough money was given
	quest::say($given);
	quest::say($cost);
	if ($given < $cost) {
		give_change($money);
		return 0;
	}
	# Enough was given
	else {
		give_change($given - $cost);
		return 1;
	}
}

my @buff_ids = (11, 18, 19, 20, 34, 66);
my $test_buying = 0;

sub EVENT_SPAWN {
	$diamondhandin = 0;
}

sub EVENT_SAY {
	if ($text=~/Hail/i) {
		quest::say("Hello [Test_Buy] [Get Change] [Teleport] [Summon Items]"); # Add to this as needed
	}
	elsif ($text=~/Teleport/i) {
		quest::say("I am still learning about teleportation, but I can send you to [" . quest::saylink("Pillars of Alra") . "], [" . quest::saylink("Icefall Glacier") . "],  or [" . quest::saylink("Cobalt Scar") . "]. Where would you like to go?")
	}
	elsif ($text =~ /Pillars of Alra/i) {
        quest::say("Begone!");
        $npc->CastSpell(29844, $userid);
    }
    elsif ($text =~ /Icefall Glacier/i) {
        quest::say("Good luck!");
        $npc->CastSpell(10874, $userid);
    }
    elsif ($text =~ /Cobalt Scar/i) {
        quest::say("Cobalt Scar it is!");
        $npc->CastSpell(2025, $userid);
    }
	elsif ($text =~ /Summon Items/i) {
		quest::say("I can summon an item for you, please give me one Diamond and then tell me the id of the item you would like");
	}
	elsif ($text=~/(\d{1,6})/i) {
		$itemNum = $text;
		if ($diamondhandin) {
			quest::say("Here is your item");
			quest::summonitem($itemNum);
			$diamondhandin = 0;
		} else {
			quest::say("I charge one Diamond for my services. Please hand me it and then ask again.");
		}

	}
	elsif ($text=~/Leave/i) {
		# Reset any variables about where the player is in the flowchart
		$test_buying = 0;
		$getting_change = 0;
	}


	if ($text=~/Test_Buy/i) {
		quest::say("Give me 77 copper for literally nothing, or [Leave]");
		$test_buying = 1;
	}
};

sub EVENT_ITEM {
	my $money = $copper + 10*($silver + 10*($gold + 10*$platinum));
	my $item = $text;

	# 10037 == diamond
	if (plugin::check_handin(\%itemcount, 10037 => 1)) {
		quest::say("Thank you for the diamond. Please tell me the ID of the item you want.");
		$diamondhandin = 1;
	}

	# if ($test_buying) {
	# 	if (buy_return($money, 77)) {
	# 		quest::say("Thanks for the 77c");
	# 	}
	# 	else {
	# 		quest::say("Not enough, give me more or [Leave]");
	# 	}
	# }
	# elsif (...) {...}
	# else {
	# 	quest::say("Thanks for the tip, here's something for your generosity");
		
	# 	my $buff_index = int(rand(scalar @buff_ids));
	# 	quest::selfcast($buff_ids[$buff_index]);
		
	# 	if ($money >= 1000) {
	# 		give_change($money - 1000);
	# 	}
	# }

	#return any unused items
	plugin::return_items(%itemcount);
}