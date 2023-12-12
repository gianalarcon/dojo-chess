use starknet::ContractAddress;
use chess::models::piece::Vec2;
#[starknet::interface]
trait IActions<ContractState> {
    fn move(
        self: @ContractState,
        curr_position: Vec2,
        next_position: Vec2,
        caller: ContractAddress, //player
        game_id: u32
    );
    fn spawn(
        self: @ContractState, white_address: ContractAddress, black_address: ContractAddress
    ) -> u32;
}

#[dojo::contract]
mod actions {
    use chess::models::player::{Player, Color};
    use chess::models::piece::{Piece, PieceType, PieceTrait};
    use chess::models::game::{Game, GameTurn, GameTurnTrait};
    use super::{ContractAddress, IActions, Vec2};

    #[external(v0)]
    impl IActionsImpl of IActions<ContractState> {
        fn spawn(
            self: @ContractState, white_address: ContractAddress, black_address: ContractAddress
        ) -> u32 {
            let world = self.world_dispatcher.read();
            let game_id = world.uuid();

            // set Players
            set!(
                world,
                (
                    Player { game_id, address: black_address, color: Color::Black(()) },
                    Player { game_id, address: white_address, color: Color::White(()) },
                )
            );

            // set Game and GameTurn    
            set!(
                world,
                (
                    Game {
                        game_id, winner: Color::None(()), white: white_address, black: black_address
                    },
                    GameTurn { game_id, player_color: Color::White(()) },
                )
            );

            // set Pieces
            set!(
                world,
                (Piece {
                    color: Color::White(()),
                    position: Vec2 { x: 0, y: 0 },
                    piece_type: PieceType::Rook
                })
            );
            set!(
                world,
                (Piece {
                    color: Color::White(()),
                    position: Vec2 { x: 0, y: 1 },
                    piece_type: PieceType::Pawn
                })
            );
            set!(
                world,
                (Piece {
                    color: Color::Black(()),
                    position: Vec2 { x: 1, y: 6 },
                    piece_type: PieceType::Pawn
                })
            );
            set!(
                world,
                (Piece {
                    color: Color::White(()),
                    position: Vec2 { x: 1, y: 0 },
                    piece_type: PieceType::Knight
                })
            );

            //the rest of the positions on the board goes here....

            game_id
        }
        fn move(
            self: @ContractState,
            curr_position: Vec2,
            next_position: Vec2,
            caller: ContractAddress, //player
            game_id: u32
        ) {
            let world = self.world_dispatcher.read();
            let mut current_piece = get!(
                world, (game_id, curr_position.x, curr_position.y), (Piece)
            );
            // check if next_position is out of board or not
            assert(PieceTrait::is_out_of_board(next_position), 'Should be inside board');

            // check if this is the right move for this piece type
            assert(
                current_piece.is_right_piece_move(curr_position, next_position),
                'Illegal move for type of piece'
            );
            let target_piece = current_piece.piece_type;
            // make current_piece piece none and move piece to next_position
            current_piece.piece_type = PieceType::None(());
            let mut piece_next_position = get!(world, (game_id, next_position), (Piece));

            // check the piece already in next_position
            let player = get!(world, (game_id, caller), (Player));
            assert(
                piece_next_position.piece_type == PieceType::None(())
                    || !piece_next_position.is_mine(@player.color),
                'Already same color piece exist'
            );
            piece_next_position.piece_type = target_piece;
            set!(world, (piece_next_position));
            set!(world, (current_piece));

            // change turn
            let mut game_turn = get!(world, game_id, (GameTurn));
            game_turn.player_color = game_turn.next_turn();
            set!(world, (game_turn));
        }
    }
}

#[cfg(test)]
mod tests {
    use starknet::ContractAddress;
    use dojo::test_utils::{spawn_test_world, deploy_contract};
    use dojo::world::{IWorldDispatcher, IWorldDispatcherTrait};
    use chess::models::player::{Player, Color, player};
    use chess::models::piece::{Piece, PieceType, Vec2, piece};
    use chess::models::game::{Game, GameTurn, game, game_turn};
    use chess::actions::{actions, IActionsDispatcher, IActionsDispatcherTrait};

    // helper setup function
    fn setup_world() -> (IWorldDispatcher, IActionsDispatcher) {
        // models
        let mut models = array![
            game::TEST_CLASS_HASH,
            player::TEST_CLASS_HASH,
            game_turn::TEST_CLASS_HASH,
            piece::TEST_CLASS_HASH
        ];
        // deploy world with models
        let world = spawn_test_world(models);

        // deploy systems contract
        let contract_address = world
            .deploy_contract('salt', actions::TEST_CLASS_HASH.try_into().unwrap());
        let actions_system = IActionsDispatcher { contract_address };

        (world, actions_system)
    }
    #[test]
    #[available_gas(3000000000000000)]
    fn test_initiate() {
        let white = starknet::contract_address_const::<0x01>();
        let black = starknet::contract_address_const::<0x02>();
        let (world, actions_system) = setup_world();

        //system calls
        let game_id = actions_system.spawn(white, black);

        //get game
        let game = get!(world, game_id, (Game));
        let game_turn = get!(world, game_id, (GameTurn));
        assert(game_turn.player_color == Color::White(()), 'should be white turn');
        assert(game.white == white, 'white address is incorrect');
        assert(game.black == black, 'black address is incorrect');

        //get a1 piece
        let curr_pos = Vec2 { x: 0, y: 0 };
        let a1 = get!(world, (game_id, curr_pos), (Piece));
        assert(a1.piece_type == PieceType::Rook, 'should be Rook');
        assert(a1.color == Color::White(()), 'should be white color');
        assert(a1.piece_type != PieceType::None, 'should have piece');
    }
    #[test]
    #[available_gas(3000000000000000)]
    fn test_move() {
        let white = starknet::contract_address_const::<0x01>();
        let black = starknet::contract_address_const::<0x02>();

        let (world, actions_system) = setup_world();
        let game_id = actions_system.spawn(white, black);
        let curr_pos = Vec2 { x: 0, y: 1 };
        let a2 = get!(world, (game_id, curr_pos), (Piece));
        assert(a2.piece_type == PieceType::Pawn, 'should be White Pawn');
        assert(a2.color == Color::White(()), 'should be white color piece');
        assert(a2.piece_type != PieceType::None, 'should have piece');

        let next_pos = Vec2 { x: 0, y: 2 };
        let game_turn = get!(world, game_id, (GameTurn));
        assert(game_turn.player_color == Color::White(()), 'should be white player turn');
        actions_system.move(curr_pos, next_pos, white.into(), game_id);

        let c3 = get!(world, (game_id, 0, 2), (Piece));
        assert(c3.piece_type == PieceType::Pawn, 'should be White Pawn');
        assert(c3.color == Color::White(()), 'should be white color piece');
        assert(c3.piece_type != PieceType::None, 'should have piece');

        let game_turn = get!(world, game_id, (GameTurn));
        assert(game_turn.player_color == Color::Black(()), 'should be black player turn');
    }
}
