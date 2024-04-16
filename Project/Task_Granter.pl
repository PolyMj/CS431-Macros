use constant FLAG => "-test";

sub EVENT_SAY {
	if ($text=~/Hail/i) {
		if (!quest::istaskactive(TASK)) { quest::assigntask(TASK); }
		quest::say("[Check] [Reset]");
	}
	elsif ($text=~/Check/i) {
		my $bucket_key = $client->CharacterID() . "-test";
		quest::say(quest::get_data($bucket_key));
	}
	else {
		my $bucket_key = $client->CharacterID() . "-test";
		quest::set_data($bucket_key, int($text));
	}
}


# Greater faydark - Giant chessboard
# One on an island in timmers deep