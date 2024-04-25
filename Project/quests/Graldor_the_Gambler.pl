# Graldow starts the quest The Gambler's Reckoning
# 
sub EVENT_SAY { 
if($text=~/Hail/i){

quest::say("Ah, greetings adventurer. I see the winds of fate have brought you here. Perhaps you could assist me in a matter of [grave importance]"); 
}
elsif ($text =~/grave importance/i) {
    quest::say(" I fear I've made a grievous error, one that may cost me dearly. You see, in a moment of reckless indulgence, I wagered an [item] of immense personal significance in a game of chance.");
}
elsif ($text =~/item/i) {
    quest::say("It is a family heirloom, passed down through generations. It's loss weighs heavily upon me. [Where did you lose it?]");
}
elsif ($text =~/Where did you lose it?/i) {
    quest::say("At the King's Court Casino, a den of vice and temptation. I was drawn into a game of Dragon's Chance, and before I knew it, the pendant was on the table, lost in the shuffle of cards and coins. If you can find it, please return it to me.");
    my $bucket_key = $client->CharacterID() . "-the-gamblers-reckoning";
    my $bucket_value = 70;
    quest::set_data($bucket_key, $bucket_value);

    if(quest::get_data($bucket_key)) {
        quest::say("success! bucket key is ($bucket_key)");
    }
    else {
        quest::say("Fail!")
    }
}
};

sub EVENT_ITEM {
    if (plugin::check_handin(\%itemcount, 10037 => 1)) {
        if($client->GetBucket("the-gamblers-reckoning")) {
            quest::say("Success!");
            # quest::delete_data($bucket_key);
            # quest::say("success! bucket key is ($bucketvalue)");
        }
        else {
             quest::say("Where did you get this?");
           #  quest::say("fail! bucket key is ($bucketvalue)");
        }
	}
};