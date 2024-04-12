my $is_playing_chess = 0;

sub EVENT_SAY {
	if ($is_playing_chess) {
		chess($text);
	}
	
	elsif ($text=~/Hail/i) {
		quest::say("Hello [Test_Buy] [Get Change] [Chess] [Test]"); # Add to this as needed
		$is_playing_chess = 1;
		chess();
	}
};

sub EVENT_ITEM {
	my $money = $copper + 10*($silver + 10*($gold + 10*$platinum));
}


# Literally chess
# empty=1, pawn=
# +10 means white, +20 means black
my $npc_c = "";
my $plr_c = "";
my $emp_s = "__";

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


sub chess {
	my ($text) = @_;
	initialize_chess();
	display_chessboard();
}

sub display_chessboard {	
	for my $row (@chessboard) {
		my $row_str = "";
		for my $square(@$row) {
			$row_str = $row_str . id_to_fullstr($square) . ' ';
		}
		quest::say($row_str);
	}
}

# IDs:
	# Default / Empty = 0
	# Non-empty = 1
	# Types:
		# Pawn => +0~7
		# Bishop => +8~9
		# Rook => +10~11
		# Knight => ~12~13
		# King => +14
		# Queen => +15
	# Teams
		# Player => +0
		# NPC => +17
	# If not empty (nonzero), can decrement by 1, then % 16 to get piece type

my $pawn = 'p', $bishop = 'b', $rook = 'p', $knight = 'n', $queen = 'Q-', $king = 'Kk';

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
			return $piece_str . $pawn . $id;
		}
		elsif ($id < 10) {
			return $piece_str . $bishop . ($id-8);
		}
		elsif ($id < 12) {
			return $piece_str . $rook . ($id-10);
		}
		elsif ($id < 14) {
			return $piece_str . $knight . ($id-12);
		}
		elsif ($id < 15) {
			return $piece_str . $king;
		}
		else {
			return $piece_str . $queen;
		}
	}
	else {
		return $emp_s;
	}
}

sub id_to_fullstr {
	my ($id) = @_;
	if ($id > 0 && $id < 17) {
		return '[' . id_to_piece($id) . ']';
	}
	else {
		return '|' . id_to_piece($id) . '|';
	}
}

sub piece_to_id {
	my ($piece) = @_;
}

sub initialize_chess {
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