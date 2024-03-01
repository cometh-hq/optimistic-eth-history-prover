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
    let program_address = "0x9DFBC5488CDE99Bfd45a541C7E04988C2c846731".to_string();
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

    {
        let block = U256::from(5387881);
        let block_hash: [u8; 32] = hex::decode("ba1ccebd78a1eabac826e8b553f7e110922cb4ab796d5cb178df82cf89d95fca").unwrap().try_into().unwrap();

        let tx = history_prover.set_block_hash(block, block_hash).send().await?.await?;
        println!("tx receipt = {:?}", tx);
    }
    {
        let block = U256::from(5348475);
        let block_hash: [u8; 32] = hex::decode("dab5a01b3fde9b7488281a36964b8d70fa1d32c7c118fd3323d3d139469b5b22").unwrap().try_into().unwrap();

        let tx = history_prover.set_block_hash(block, block_hash).send().await?.await?;
        println!("tx receipt = {:?}", tx);
    }

    Ok(())
}


