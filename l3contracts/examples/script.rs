use ethers::{
    middleware::SignerMiddleware,
    prelude::abigen,
    providers::{Http, Middleware, Provider},
    signers::{LocalWallet, Signer},
    types::{Address, U256},
};
use std::str::FromStr;
use std::sync::Arc;


#[tokio::main]
async fn main() -> eyre::Result<()> {


    let rpc_url = "https://stylus-testnet.arbitrum.io/rpc".to_string();
    let program_address = "0x3437eE5D96278B9Bf26DB8a1E3056058dB231820".to_string();
    let privkey = "0x".to_string();

    abigen!(
        HistoryProver,
        r#"[
            function setBlockHash(uint256 block_number, bytes32 block_hash) external;
            function verifyExecutionPayloadHeader(bytes calldata execution_payload_header) external;
        ]"#
    );

    let provider = Provider::<Http>::try_from(rpc_url)?;
    let address: Address = program_address.parse()?;

    let wallet = LocalWallet::from_str(&privkey)?;
    let chain_id = provider.get_chainid().await?.as_u64();
    let client = Arc::new(SignerMiddleware::new(
        provider,
        wallet.clone().with_chain_id(chain_id),
    ));

    // Prover contract
    let history_prover = HistoryProver::new(address, client);

    // hash and block_number for block 1
    let block_hash: [u8; 32] = hex::decode("88e96d4537bea4d9c05d12549907b32561d3bf31f45aae734cdc119f13406cb6").unwrap().try_into().unwrap();
    let block_number = U256::from(1);


    let first_tx = history_prover.set_block_hash(block_number, block_hash).send().await?.await?;
    println!("First Tx = {:?}", first_tx);

    Ok(())
}


