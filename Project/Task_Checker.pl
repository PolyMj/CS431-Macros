use constant TASK => 505747;
use constant ACTIVITY => 0;

sub EVENT_SAY {
	if ($text=~/Hail/i) {
		if (!quest::istaskactive(TASK)) { quest::assigntask(TASK); }
		quest::say("Give me a number to set your done_count to [Check Current] [Reset]");
	}
	elsif ($text=~/Check Current/i) {
		quest::say(quest::gettaskactivitydonecount(TASK, ACTIVITY));
	}
	elsif ($text=~/Reset/i) {
		quest::resettaskactivity(TASK, ACTIVITY);
	}
	else {
		my $new = int($text);
		my $current = quest::gettaskactivitydonecount(TASK, ACTIVITY);
		quest::say("Setting it to " . $new . " | Incrementing by " . ($new-$current));
		quest::resettaskactivity(TASK, ACTIVITY);
		quest::updatetaskactivity(TASK, ACTIVITY, $new, 0);
	}
}


# Greater faydark - Giant chessboard
# One on an island in timmers deep