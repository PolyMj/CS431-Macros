# Graldow starts the quest The Gambler's Reckoning
# 
sub EVENT_SAY { 
if($text=~/Hail/i){
    my $bucket_key = $client->CharacterID() . "-the-gamblers-reckoning";
    if(quest::get_data($bucket_key) == 2) {
        quest::say("Thank you again for returning my pendant, I don't know what I would have done without you.[reset bucket]");
    }
    elsif(quest::get_data($bucket_key) == 1) {
        quest::say("Have you found it yet? They should have it at the King's Court Casino. Please hurry![reset bucket]");
    } else {
        quest::say("Ah, greetings adventurer. I see the winds of fate have brought you here. Perhaps you could assist me in a matter of [grave importance]? [reset bucket]"); 
    }
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
    my $bucket_value = 1;
    quest::set_data($bucket_key, $bucket_value);

    if(quest::get_data($bucket_key)) {
        quest::say("success! bucket key is ($bucket_key)");
    }
    else {
        quest::say("Fail!");
    }
}
elsif ($text =~/reset bucket/i) {
    my $bucket_key = $client->CharacterID() . "-the-gamblers-reckoning";
    quest::set_data($bucket_key, 0);
    quest::say("Bucket reset");
}
};

sub EVENT_ITEM {
    # 36465 is a lore item jade pendant
    if (plugin::check_handin(\%itemcount, 36465 => 1)) {
        my $bucket_key = $client->CharacterID() . "-the-gamblers-reckoning";
        if(quest::get_data($bucket_key) == 1) {
            quest::say("By the stars, you actually found it! My family's pendant, returned to me. I never thought I'd see it again. I don't have much to give you but here, please take this.");
            #todo change reward to something more relevant
            quest::summonitem(quest::ChooseRandom(13053, 10010, 10018, 10017));
            quest::ding();
            #status 2 for quest completed
            quest::set_data($bucket_key, 2);
        }
        else {
             quest::say("Where did you get this?");
        }
	}
    plugin::return_items(%itemcount);
};