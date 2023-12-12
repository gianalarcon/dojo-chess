use starknet::ContractAddress;

#[derive(Model, Drop, Serde)]
struct Piece {
    #[key]
    color: Color,
    #[key]
    position: Vec2,
    piece_type: PieceType,
}

#[derive(Copy, Drop, Serde, Introspect)]
struct Vec2 {
    x: u32,
    y: u32
}

#[derive(Serde, Drop, Copy, PartialEq, Introspect)]
enum PieceType {
    Pawn: (),
    Knight: (),
    Bishop: (),
    Rook: (),
    Queen: (),
    King: (),
    None: (),
}

#[derive(Serde, Drop, Copy, PartialEq, Introspect)]
enum Color {
    White: (),
    Black: (),
    None: (),
}

#[derive(Model, Drop, Serde)]
struct Game {
    #[key]
    game_id: u32,
    winner: Color,
    white: ContractAddress,
    black: ContractAddress
}

#[derive(Model, Drop, Serde)]
struct Player {
    #[key]
    game_id: u32,
    #[key]
    address: ContractAddress,
    color: Color
}

#[derive(Model, Drop, Serde)]
struct GameTurn {
    #[key]
    game_id: u32,
    player_color: Color
}
