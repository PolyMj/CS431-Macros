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
# Same as above but can but buys the maximum number of items
sub buy_max_return {
	my ($given, $cost) = @_;
	# If not enough money was given
	if ($given < $cost) {
		give_change($money);
		return 0;
	}
	# Enough was given
	else {
		my $count = $given / $cost;
		give_change($given - $cost * $count);
		return $count;
	}
}

my @buff_ids;
my $test_buying;
my $is_playing_chess;
my $asking_about_chess;
my $buying_levels;
my $buying_AA;

sub EVENT_SPAWN {
	reset_conditions();
}

sub reset_conditions {
	$diamondhandin = 0;
	@buff_ids = (11, 18, 19, 20, 34, 66);
	$test_buying = 0;
	$is_playing_chess = 0;
	$asking_about_chess = 0;
	$buying_levels = 0;
	$buying_AA = 0;
}

sub EVENT_SAY {
	if ($is_playing_chess) {
		chess($text);
		return;
	}
	
	if ($text=~/Hail/i) {
		quest::say("Hey there, whatcha need? [Teleport] [Summon Items] [Make some money] [Buy Levels] [Buy AA]"); # Add to this as needed
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
		reset_conditions();
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
		reset_conditions();
	}
	elsif ($text=~/Make some money/i) {
		reset_conditions();
		quest::say("I'm pretty bad at chess. I'll bet you 250 platinum that I'll lose to you. Deal?");
		$asking_about_chess = 1;
	}
	elsif ($text=~/Buy Levels/i) {
		reset_conditions();
		quest::say("Alright, I sell 'em for 7,600 platinum a pieces, so drop me some and I'll fix you up.");
		$buying_levels = 1;
	}
	elsif ($text=~/Buy AA/i) {
		reset_conditions();
		if (quest::getlevel(0) >= 52) {
			quest::say("Alright, I sell 'em for 12,400 platinum a piece, so drop me some and I'll fix you up.");
			$buying_AA = 1;
		}
		else {
			quest::say("Sorry, we don't give these things out to just anyone. Come back when you're a bit tougher.");
		}
		
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

	if ($asking_about_chess) {
		if (buy_return($money, 250000)) {
			quest::say("Let's start!");
			$is_playing_chess = 1;
			initialize_chess();
		}
		else {
			quest::say("Cheap schmuck");
		}
	}
	elsif ($buying_levels) {
		my $count = buy_max_return($money, 7600000);
		if ($count) {
			quest::level(quest::getlevel(0) + $count);
			quest::say("Pleasure doin business!");
		}
		else {
			quest::say("Sorry, that won't cut it. Need at least 7,600 plat.");
		}
	}
	elsif ($buying_AA) {
		my $count = buy_max_return($money, 12400000);
		if ($count) {
			$client->AddAAPoints($count);
			quest::say("Pleasure doin business!");
		}
		else {
			quest::say("Sorry, that won't cut it. Need at least 7,600 plat.");
		}
	}

	# return any unused items
	plugin::return_items(%itemcount);
}





### Literally just chess down here ###
my $npc_c = "";
my $plr_c = "";
my $emp_s = "__";

my $selected_piece = [-1,-1]; # Position of selected peice
# Each element is the valid moves of the row, with each bit of the 
# number being a boolean of whether that square is a valid option
my @valid_moves = (0, 0, 0, 0, 0, 0, 0, 0); 

my @chessboard = (
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0],
	[0, 0, 0, 0, 0, 0, 0, 0]
);

# Square Values:
	# Default / Empty = 0
	# Non-empty = 1
	# Types:
		# Pawn => +0~7
		# Bishop => +8~9
		# Rook => +10~11
		# Knight => ~12~13
		# Queen => +14
		# King => +15
	# Teams
		# Player => +0
		# NPC => +16
	# If not empty (nonzero), can decrement by 1, then % 16 to get piece type

my $pawn = 'p', $bishop = 'b', $rook = 'u', $knight = 'n', $queen = 'Q-', $king = 'Kk';

# Run a round of chess
sub chess {
	my ($text) = @_;

	if ($text=~/Hail/i) {
		initialize_chess();
	}
	else {
		click($text);
	}

	if ($is_playing_chess) {
		display_chessboard();
	}
}

# Checks if a player has won
sub check_win {
	my ($plr_king_alive, $npc_king_alive) = (0,0);

	for my $rowi (0..$#chessboard) {
		for my $coli (0..$#{$chessboard[$rowi]}) {
			if ($chessboard[$rowi][$coli] == 16) {
				$plr_king_alive = 1;
			}
			if ($chessboard[$rowi][$coli] == 32) {
				$npc_king_alive = 1;
			}
		}
	}

	if ($plr_king_alive && $npc_king_alive) {
		return 0;
	}
	$is_playing_chess = 0;
	if ($plr_king_alive) {
		quest::say("Yeah as expected, you won. Guess I'll use my 'victory' money to drown my woes in booze...");
		return 1;
	}
	quest::say("I won? Well I'll be damned. Here's your 250 platinum, like promised.");
	give_change(250000);
	return 1
}

# Check what the player has clicked
sub click {
	my ($text) = @_;
	my $id = piece_to_id($text);
	if ($id == -1) {
		# Not a piece, so check if it's a move
		parse_move($text);
		return;
	}

	# If selected a piece, find the valid moves for that piece
	my ($prow, $pcol) = find_piece($id);
	$selected_piece = [$prow, $pcol];
	find_moves();
}

# Convert a move instruction (e.g. A4) to an actual move
sub parse_move {
	my ($movestr) = @_;
	my $nrow = 8-int(substr($movestr, 0, 1));
	my $ncol = ord(substr($movestr, 1, 2))-65;

	move($nrow, $ncol);

	npc_move(); # Let the NPC have their turn
	check_win();
}

# Move the selected piece to a new positon
sub move {
	my ($nrow, $ncol) = @_;
	if ($nrow < 0 || $ncol < 0 || $nrow > 7 || $ncol > 7) {
		return;
	}

	my ($row, $col) = @$selected_piece;
	$chessboard[$nrow][$ncol] = $chessboard[$row][$col];
	$chessboard[$row][$col] = 0;
	$selected_piece = [-1, -1];
	clear_moves();
}

# NPC's turn
sub npc_move {
	my @pieces = ();
	
	# Get all pieces
	for my $rowi (0..$#chessboard) {
		for my $coli (0..$#{$chessboard[$rowi]}) {
			if ($chessboard[$rowi][$coli] > 16) {
				push(@pieces, [$rowi, $coli]);
			}
		}
	}

	# While there are still pieces that haven't been checked
	while (scalar @pieces) {
		# Select a random piece
		$rindex = int(rand(scalar @pieces));
		($selected_piece) = (splice(@pieces, $rindex, 1));
		@selected_piece = @$selected_piece;
		quest::say("NPC - " . $selected_piece->[0] . ", " . $selected_piece->[1]);
		
		
		# Get all valid moves for this piece
		find_moves();
		my @valids = ();
		for my $row (0..$#valid_moves) {
			my $val = $valid_moves[$row];
			for $col (0..7) {
				if ($val % 2) {
					push(@valids, [$row, $col]);
				}
				$val /= 2;
			}
		}

		# If there are valid moves for this piece
		if (scalar @valids) {
			# Random valid move
			my ($move) = $valids[int(rand(scalar @valids))];
			@move = @$move;
			move($move->[0], $move->[1]);
			return;
		}

	}
	if (!(scalar @pieces)) {
		quest::say("You win!");
		# No moves, player wins
	}
}

# Find a specific piece on the board
sub find_piece {
	my ($p_id) = @_;

	for my $rowi (0..$#chessboard) {
		for my $coli (0..$#{$chessboard[$rowi]}) {
			if ($chessboard[$rowi][$coli] == $p_id) {
				return ($rowi, $coli);
			}
		}
	}

	return (-1, -1);
}

# Print out the entire chessboard
sub display_chessboard {	
	for my $rowi (0..$#chessboard) {
		my $row_str = (8-$rowi) . ' : ';
		my $vmove = $valid_moves[$rowi];
		for my $coli (0..$#{$chessboard[$rowi]}) {
			if ($vmove % 2) {
				$row_str = $row_str . '[' . (8-$rowi) . chr($coli+65) . '] ';
			}
			else {
				my $square = $chessboard[$rowi][$coli];
				$row_str = $row_str . id_to_fullstr($square) . ' ';
			}

			$vmove = $vmove / 2;
		}
		last if $rowi >= 8;
		quest::say($row_str);
	}
}

# Convert from an id to a piece string
sub id_to_piece {
	my ($id) = @_;
	if ($id) {
		my $piece_str = "";
		$id = $id-1;
		if ($id < 16) {
			$piece_str = $piece_Str . $plr_c;
		}
		else {
			$piece_str = $piece_str . $npc_c;
			$id = $id % 16;
		}

		if ($id < 8) {
			return $piece_str . $pawn . ($id+1);
		}
		elsif ($id < 10) {
			return $piece_str . $bishop . ($id-7);
		}
		elsif ($id < 12) {
			return $piece_str . $rook . ($id-9);
		}
		elsif ($id < 14) {
			return $piece_str . $knight . ($id-11);
		}
		elsif ($id < 15) {
			return $piece_str . $queen;
		}
		else {
			return $piece_str . $king;
		}
	}
	else {
		return $emp_s;
	}
}

# Add brackets or lines depending on whether it's the player or NPC's piece
sub id_to_fullstr {
	my ($id) = @_;
	if ($id > 0 && $id < 17) {
		return '[' . id_to_piece($id) . ']';
	}
	else {
		return '|' . id_to_piece($id) . '|';
	}
}

# Convert from a piece string to an ID
sub piece_to_id {
	my ($piece) = @_;
	if ($piece eq $emp_s) {
		return 0;
	}
	
	if (substr($piece, 0, 2) eq $queen) {
		return 15;
	}
	elsif (substr($piece, 0, 2) eq $king) {
		return 16;
	}
	else {
		my $type = substr($piece, 0, 1);
		my $num = int(substr($piece, 1, 2)) - 1;
		if ($type eq $pawn) {
			return 1 + $num
		}
		elsif ($type eq $bishop) {
			return 9 + $num;
		}
		elsif ($type eq $rook) {
			return 11 + $num;
		}
		elsif ($type eq $knight) {
			return 13 + $num;
		}
	}

	return -1;
}

# Initialize all piece positions
sub initialize_chess {
	# Clear the board
	for my $row (@chessboard) {
		for my $square (@$row) {
			$square = 0;
		}
	}
	
	# Pawns
	for my $pawn_num (0..7) {
		$chessboard[1][$pawn_num] = 17 + $pawn_num;
		$chessboard[6][$pawn_num] = 1 + $pawn_num;
	}
	
	# Bishops
	$chessboard[0][2] = 17+8;
	$chessboard[0][5] = 17+9;
	$chessboard[7][2] = 1+8;
	$chessboard[7][5] = 1+9;
	
	# Rooks
	$chessboard[0][0] = 17+10;
	$chessboard[0][7] = 17+11;
	$chessboard[7][0] = 1+10;
	$chessboard[7][7] = 1+11;
	
	# Knights
	$chessboard[0][1] = 17+12;
	$chessboard[0][6] = 17+13;
	$chessboard[7][1] = 1+12;
	$chessboard[7][6] = 1+13;

	# Queen
	$chessboard[0][3] = 17+14;
	$chessboard[7][3] = 1+14;

	# King
	$chessboard[0][4] = 17+15;
	$chessboard[7][4] = 1+15;
}

# Clear @valid_moves
sub clear_moves {
	for my $i (0..8) {
		$valid_moves[$i] = 0;
	}
}

# Fill @valid_moves depending on the selected piece
sub find_moves {
	my ($row, $col) = @$selected_piece;
	clear_moves();
	if ($selected_piece->[0] < 0 || $selected_piece->[1] < 0) {
		return;
	}

	my $p_id = $chessboard[$row][$col];
	my $is_plr = ($p_id < 17);
	my $type = ($p_id - 1) % 16;
	if ($p_id) {
		if ($type < 8) {
			move_pawn($p_id);
		}
		elsif ($type < 10) {
			move_bishop($p_id);
		}
		elsif ($type < 12) {
			move_rook($p_id);
		}
		elsif ($type < 14) {
			move_knight($p_id);
		}
		elsif ($type < 15) {
			move_queen($p_id);
		}
		else {
			move_king($p_id);
		}
	}
}

# Checks if there are valid moves currently
sub are_valid_moves {
	for $i (0..7) {
		if ($valid_moves[$i]) {
			return 1;
		}
	}
	return 0;
}

# Assumes you checked square status
sub add_move {
	my ($row, $col) = @_;
	if ($row < 0 || $row > 7 || $col < 0 || $col > 7) {
		return 0;
	}
	else {
		$valid_moves[$row] += 2 ** $col;
	}
}

# Returns 'true' if it's a valid spot, false otherwise
# More specifically, returns 1 if empty, 0 if friendly piece, -1 if enemy
sub square_status {
	my ($p_id, $row, $col) = @_;
	my $square = $chessboard[$row][$col];
	if ($square) {
		if ($square > 16 == $p_id > 16) {
			return 0;
		}
		else {
			return -1;
		}
	}
	else {
		return 1;
	}
}

sub move_pawn {
	my ($p_id) = @_;
	my ($row, $col) = @$selected_piece;
	my $dir = -1;
	
	if ($p_id > 16) {
		$dir = 1;
	}
	
	for $c (($col-1)..($col+1)) {
		my $stat = square_status($p_id, ($row+$dir), $c);
		if ($stat) {
			if ($stat == -1) {
				add_move($row+$dir, $c);
			}
			elsif ($c == $col) {
				add_move($row+$dir, $c);
			}
		}
	}
}

sub move_bishop {
	my ($p_id) = @_;
	my ($row, $col) = @$selected_piece;

	for my $i (1..7) {
		my ($nrow, $ncol) = ($row-$i, $col-$i);
		my $stat = square_status($p_id, $nrow, $ncol);
		if ($stat) {
			add_move($nrow, $ncol)
		}
		last if ($stat != 1);
	}

	for my $i (1..7) {
		my ($nrow, $ncol) = ($row+$i, $col-$i);
		my $stat = square_status($p_id, $nrow, $ncol);
		if ($stat) {
			add_move($nrow, $ncol)
		}
		last if ($stat != 1);
	}

	for my $i (1..7) {
		my ($nrow, $ncol) = ($row+$i, $col+$i);
		my $stat = square_status($p_id, $nrow, $ncol);
		if ($stat) {
			add_move($nrow, $ncol)
		}
		last if ($stat != 1);
	}

	for my $i (1..7) {
		my ($nrow, $ncol) = ($row-$i, $col+$i);
		my $stat = square_status($p_id, $nrow, $ncol);
		if ($stat) {
			add_move($nrow, $ncol)
		}
		last if ($stat != 1);
	}
}

sub move_rook {
	my ($p_id) = @_;
	my ($row, $col) = @$selected_piece;

	for my $i (1..7) {
		my $nrow = $row - $i;
		my $stat = square_status($p_id, $nrow, $col);
		if ($stat) {
			add_move($nrow, $col)
		}
		last if ($stat != 1);
	}

	for my $i (1..7) {
		my $nrow = $row + $i;
		my $stat = square_status($p_id, $nrow, $col);
		if ($stat) {
			add_move($nrow, $col)
		}
		last if ($stat != 1);
	}

	for my $i (1..7) {
		my $ncol = $col - $i;
		my $stat = square_status($p_id, $row, $ncol);
		if ($stat) {
			add_move($row, $ncol)
		}
		last if ($stat != 1);
	}

	for my $i (1..7) {
		my $ncol = $col + $i;
		my $stat = square_status($p_id, $row, $ncol);
		if ($stat) {
			add_move($row, $ncol)
		}
		last if ($stat != 1);
	}
	
}

sub move_knight {
	my ($p_id) = @_;
	my ($row, $col) = @$selected_piece;

	for my $a (0..1) {
		my ($x, $y) = (1, 2);
		if ($a) {
			($x, $y) = (2, 1);
		}
		for my $i (0..1) {
			if ($i) {
				$x = -$x;
			}
			for my $j (0..1) {
				if ($j) {
					$y = -$y;
				}
				my ($nrow, $ncol) = ($row+$x, $col+$y);
				my $stat = square_status($p_id, $nrow, $ncol);
				if ($stat) {
					add_move($nrow, $ncol);
				}
			}
		}
	}
}

sub move_queen {
	my ($p_id) = @_;
	move_rook($p_id);
	move_bishop($p_id);
}

sub move_king {
	my ($p_id) = @_;
	my ($row, $col) = @$selected_piece;

	for $dx (-1..1) {
		for $dy (-1..1) {
			my ($nrow, $ncol) = ($row+$dy, $col+$dx);

			my $stat = square_status($p_id, $nrow, $ncol);
			if ($stat) {
				add_move($nrow, $ncol);
			}
		}
	}
}
