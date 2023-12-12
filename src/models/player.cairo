use starknet::ContractAddress;

#[derive(Serde, Drop, Copy, PartialEq, Introspect)]
enum Color {
    White: (),
    Black: (),
    None: (),
}

#[derive(Model, Drop, Serde)]
struct Player {
    #[key]
    game_id: u32,
    #[key]
    address: ContractAddress,
    color: Color
}
