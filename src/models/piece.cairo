use chess::models::player::Color;
use starknet::ContractAddress;

#[derive(Model, Drop, Serde)]
struct Piece {
    #[key]
    game_id: u32,
    #[key]
    position: Vec2,
    color: Color,
    piece_type: PieceType,
}

#[derive(Copy, Drop, Serde, Introspect)]
struct Vec2 {
    x: u32,
    y: u32
}

#[derive(Serde, Drop, Copy, PartialEq, Introspect)]
enum PieceType {
    Pawn,
    Knight,
    Bishop,
    Rook,
    Queen,
    King,
    None,
}

trait PieceTrait {
    fn is_out_of_board(next_position: Vec2) -> bool;
    fn is_right_piece_move(self: @Piece, curr_position: Vec2, next_position: Vec2) -> bool;
}

impl PieceImpl of PieceTrait {
    fn is_out_of_board(next_position: Vec2) -> bool {
        next_position.x > 7 || next_position.y > 7
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
            PieceType::None => panic(array!['Should not move empty piece']),
        }
    }
}
