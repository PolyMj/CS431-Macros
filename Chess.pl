# scp Chess.pl eqemu@192.168.56.3:server/quests/netherbian/TestQuest.pl

my $is_playing_chess = 1;

sub EVENT_SAY {
	chess($text);
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

my @selected_piece = (-1,-1);
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


sub chess {
	my ($text) = @_;

	if ($text=~/Hail/i) {
		initialize_chess();
	}
	else {
		click($text);
	}

	display_chessboard();
}

sub click {
	my ($piece) = @_;
	my $id = piece_to_id($piece);
	if ($id == -1) {
		parse_move($piece);
		return;
	}

	my ($prow, $pcol) = find_piece($id);
	@selected_piece = ($prow, $pcol);
	find_moves();

	# TEMP
	quest::say("Clicked: " . $prow . ", " . $pcol);
}

sub parse_move {
	my ($movestr) = @_;
	my $nrow = 8-int(substr($movestr, 0, 1));
	my $ncol = ord(substr($movestr, 1, 2))-65;

	quest::say("(" . $movestr . ") Move to " . $nrow . ", " . $ncol);

	if ($nrow < 0 || $ncol < 0 || $nrow > 7 || $ncol > 7) {
		return;
	}

	my ($row, $col) = @selected_piece;
	$chessboard[$nrow][$ncol] = $chessboard[$row][$col];
	$chessboard[$row][$col] = 0;

	clear_moves();
}


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

my $pawn = 'p', $bishop = 'b', $rook = 'u', $knight = 'n', $queen = 'Q-', $king = 'Kk';

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
			return 13 + num;
		}
	}

	quest::say("Error: Unknown piece");
	return -1;
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

sub clear_moves {
	for my $i (0..8) {
		$valid_moves[$i] = 0;
	}
}

sub find_moves {
	my ($row, $col) = @selected_piece;
	clear_moves();
	if ($selected_piece[0] < 0 || $selected_piece[1] < 0) {
		return;
	}

	my $p_id = $chessboard[$row][$col];
	if ($p_id) {
		if ($id < 8) {
			move_pawn($p_id);
		}
		elsif ($id < 10) {
			
		}
		elsif ($id < 12) {
			
		}
		elsif ($id < 14) {
			
		}
		elsif ($id < 15) {
			
		}
		else {
			
		}
	}
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

# Returns 1 if empty, 0 if friendly piece, -1 if enemy
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
	my ($row, $col) = @selected_piece;
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