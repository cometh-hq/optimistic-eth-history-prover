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
    let privkey = std::env::var("PRIVATE_KEY").unwrap();

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

    let block = U256::from(5357043);
    let block_hash: [u8; 32] = hex::decode("73646fba8d16801b16e94aa7a89d4e21db95e03537317b3a378b34cacda0ebde").unwrap().try_into().unwrap();

    let tx = history_prover.set_block_hash(block, block_hash).send().await?.await?;
    println!("tx receipt = {:?}", tx);

    Ok(())
}


