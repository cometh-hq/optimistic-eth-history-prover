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
    let program_address = "0xDf859c81287DD1aAcA02d3F56Eaa4dD3C5615EA3".to_string();
    let privkey = "0x".to_string();

    abigen!(
        HistoryProver,
        r#"[
            function setBlockHash(uint256 block_number, bytes32 block_hash) external;
            function verifyExecutionPayloadHeader(uint8[] memory execution_payload_header) external;
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

    // header for block 1
    let block_header = hex::decode("f90211a0d4e56740f876aef8c010b86a40d5f56745a118d0906a34e69aec8c0db1cb8fa3a01dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d493479405a56e2d52c817161883f50c441c3228cfe54d9fa0d67e4d450343046425ae4271474353857ab860dbc0a1dde64b41b5cd3a532bf3a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421a056e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421b90100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008503ff80000001821388808455ba422499476574682f76312e302e302f6c696e75782f676f312e342e32a0969b900de27b6ac6a67742365dd65f55a0526c41fd18e1b16f1a1215c2e66f5988539bd4979fef1ec4").unwrap();

    // hash and block_number for block 1
    let block_hash: [u8; 32] = hex::decode("88e96d4537bea4d9c05d12549907b32561d3bf31f45aae734cdc119f13406cb6").unwrap().try_into().unwrap();
    let block_number = U256::from(1);


    let first_tx = history_prover.set_block_hash(block_number, block_hash).send().await?.await?;
    println!("First Tx = {:?}", first_tx);

    Ok(())
}


