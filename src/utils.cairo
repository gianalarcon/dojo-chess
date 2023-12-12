use chess::models::{PieceType, Piece, Vec2, GameTurn, Color};
use starknet::ContractAddress;

trait PieceTrait {
    fn is_mine(self: @Piece) -> bool;
    fn is_out_of_board(next_position: Vec2) -> bool;
    fn is_right_piece_move(self: @Piece, curr_position: Vec2, next_position: Vec2) -> bool;
}

impl PieceImpl of PieceTrait {
    fn is_mine(self: @Piece) -> bool {
        false
    }

    fn is_out_of_board(next_position: Vec2) -> bool {
        if next_position.x > 7 || next_position.y > 7 {
            return false;
        }
        true
    }

    fn is_right_piece_move(self: @Piece, curr_position: Vec2, next_position: Vec2) -> bool {
        let c_x = curr_position.x;
        let c_y = curr_position.y;
        let n_x = next_position.x;
        let n_y = next_position.y;
        match self.piece_type {
            PieceType::Pawn => { true },
            PieceType::Knight => {
                if n_x == c_x + 2 && n_y == c_x + 1 {
                    return true;
                }
                panic(array!['Knight illegal move'])
            },
            PieceType::Bishop => { true },
            PieceType::Rook => { true },
            PieceType::Queen => { true },
            PieceType::King => { true },
            PieceType::None(_) => panic(array!['Should not move empty piece']),
        }
    }
}

trait GameTurnTrait {
    //fn is_correct_turn(self: @GameTurn) -> bool;
    fn next_turn(self: @GameTurn) -> Color;
}
impl GameTurnImpl of GameTurnTrait {
    // fn is_correct_turn(self: @GameTurn) -> bool {

    // }
    fn next_turn(self: @GameTurn) -> Color {
        match self.player_color {
            Color::White(()) => Color::Black(()),
            Color::Black(()) => Color::White(()),
            Color::None(()) => panic(array!['Illegal turn']),
        }
    }
}
