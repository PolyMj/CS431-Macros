# Stuff to do
# Done
	# Recieving and checking money
	# Giving money
	# Removing money
	# Summoning items
	# Checking level
	# Leveling
	# Casting spells
	# Port player to zone
	# AA points


my $update_client = 1;
my $password;
my $options = "[Get Money] [Display Money] [Give Money] [Get Item] [Password] [Display Level] [Set Level] [Get AA] [To Zone] [Buff]";
my $setting_pass = 0;
my $guessing_pass = 0;
my $requesting_item = 0;
my $zoning = 0;

sub EVENT_SAY {
	if ($setting_pass) {
		$password = $text;
		quest::say("Gotcha, our new password is " . $text);
		$setting_pass = 0;
		return;
	}
	if ($guessing_pass) {
		if ($text!=~/leave/i) {
			if ($text=~/$password/i) {
				quest::say("That's it!");
				$guessing_pass = 0;
			}
			else {
				quest::say("Nah, guess again or [leave]");
			}
		}
		else {
			quest::say("Aight get outta here " . $options);
			$guessing_pass = 0;
		}
		return;
	}
	if ($requesting_item) {
		if (quest::summonitem($text)) {
			quest::say("Item summoned");
		}
		else {
			quest:say("Don't know what that is");
		}
		$requesting_item = 0;
	}
	if ($zoning) {
		if (quest::zone($text)) {
			quest::say("Zoned");
		}
		else {
			quest::say("Uh oh");
		}
	}

	if ($text=~/Hail/i) {
		quest::say("Here are your options: " . $options);
	}
	if ($text=~/Get Money/i) {
		my $copp, $silv, $gold, $plat;
		$copp = 1;
		$silv = 2;
		$gold = 3;
		$plat = 4;
		$client->AddMoneyToPP($copp, $silv, $gold, $plat, $update_client);
	}
	if ($text=~/Display Money/i) {
		my $money = $client->GetAllMoney();
		quest::say($money . " in copper");
		# quest::convertt_money_to_string(hash table);
	}
	if ($text=~/Give Money/i) {
		my $tot_in_copp = 10;
		$client->TakeMoneyFromPP($tot_in_copp, $update_client);
			# Does not check if amount exceeds current total
			# nor does it raise an error of any kind
	}
	if ($text=~/Get Item/i) {
		$requesting_item = 1;
	}
	if ($text=~/Password/i) {
		if (defined $password) {
			quest::say("What's the password?");
			$guessing_pass = 1;
		}
		else {
			quest::say("We don't have a password, give me one");
			$setting_pass = 1;
		}
	}
	if ($text=~/Display Level/i) {
		quest::say(quest::getlevel(0));
	}
	if ($text=~/Set Level/i) {
		quest::level(27);
	}
	if ($text=~/Get AA/i) {
		$client->AddAAPoints(1);
	}
	if ($text=~/To Zone/i) {
		quest::say("Pick a zone");
		$zoning = 1;
	}
	if ($text=~/Buff/i) {
		quest::castspell(11, $client->AccountID());
	}
}


sub EVENT_ITEM {
	my $money = $copper + 10*($silver + 10*($gold + 10*$platinum));
	quest::say($money);
	# $client->AddMoneyToPP($copper, $silver, $gold, $platinum, $update_client);
	quest::givecash($money);
}
