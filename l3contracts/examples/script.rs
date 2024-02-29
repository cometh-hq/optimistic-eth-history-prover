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
    let program_address = "0x6023974F44AE50635feEAaF9DEF6405f10299610".to_string();
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
    let block_hash: [u8; 32] = hex::decode("f294daaf296ac9f64a944ed11de0e090b3a3de5402b2cfc5c3216f09e9071f2d").unwrap().try_into().unwrap();
    let block_hash_bis: [u8; 32] = hex::decode("5eb3e5223cfd9e10a5408784153d7aff9cd4528cfdb431df82deafdcf54210ed").unwrap().try_into().unwrap();
    let block_number = U256::from(5387881);


    let first_tx = history_prover.set_block_hash(U256::from(5387881), block_hash).send().await?.await?;
    let first_tx = history_prover.set_block_hash(U256::from(5387614), block_hash_bis).send().await?.await?;
    println!("First Tx = {:?}", first_tx);

    Ok(())
}


