use ethers::{
    contract::Multicall,
    middleware::SignerMiddleware,
    prelude::{abigen, MULTICALL_ADDRESS},
    providers::{Http, Middleware, Provider},
    signers::{LocalWallet, Signer},
    types::{Address, Block, H256},
};
use std::str::FromStr;
use std::sync::Arc;
use reth::primitives::{Header, U256, Bytes};
use alloy_rlp::Encodable;

abigen!(
    HistoryProver,
    r#"[
        function setBlockHash(uint256 block_number, bytes32 block_hash) external;
        function verifyExecutionPayloadHeader(bytes calldata execution_payload_header) external;
    ]"#
);


fn get_header(block: &Block<H256>) -> Header {
    let blob_gas_used = block.blob_gas_used.map(|x| x.low_u64() );
    let base_fee_per_gas = block.base_fee_per_gas.map(|x| x.low_u64() );
    let excess_blob_gas = block.excess_blob_gas.map(|x| x.low_u64() );
    let timestamp = block.timestamp.low_u64();

    let mut difficulty_bytes:Vec<u8> = vec![0; 32];

    block.difficulty.to_little_endian(difficulty_bytes.as_mut_slice());
    let difficulty = U256::from_le_slice(difficulty_bytes.as_slice());

    Header {
        parent_hash: block.parent_hash.as_fixed_bytes().into(),
        ommers_hash: block.uncles_hash.as_fixed_bytes().into(),
        beneficiary: block.author.unwrap().to_fixed_bytes().into(),
        state_root: block.state_root.as_fixed_bytes().into(),
        transactions_root: block.transactions_root.as_fixed_bytes().into(),
        receipts_root: block.receipts_root.as_fixed_bytes().into(),
        withdrawals_root:block.withdrawals_root.map(|x| x.as_fixed_bytes().into()),
        logs_bloom: block.logs_bloom.unwrap().as_fixed_bytes().into(),
        difficulty,
        number: block.number.unwrap().low_u64(),
        gas_limit:block.gas_limit.low_u64(),
        gas_used:block.gas_used.low_u64(),
        timestamp:timestamp.into(),
        mix_hash:block.mix_hash.unwrap().as_fixed_bytes().into(),
        nonce:block.nonce.unwrap().to_low_u64_be(),
        base_fee_per_gas:base_fee_per_gas.into(),
        blob_gas_used:blob_gas_used.into(),
        excess_blob_gas:excess_blob_gas.into(),
        parent_beacon_block_root:block.parent_beacon_block_root.map(|x| x.as_fixed_bytes().into() ),
        extra_data:Bytes::copy_from_slice(block.extra_data.iter().as_slice()),
    }
}

#[tokio::main]
async fn async_main() -> eyre::Result<()> {

    let stylus_rpc_url = std::env::var("STYLUS_RPC_URL").unwrap();
    let mainnet_rpc_url = std::env::var("MAINNET_RPC_URL").unwrap();
    let mut start_block_number = std::env::var("START_BLOCK_NUMBER").unwrap().parse::<u64>().unwrap();
    let address: Address = "0x6023974F44AE50635feEAaF9DEF6405f10299610".to_string().parse()?;
    let privkey = std::env::var("PRIVATE_KEY").unwrap();

    let stylus_provider = Provider::<Http>::try_from(stylus_rpc_url)?;
    let mainnet_provider = Provider::<Http>::try_from(mainnet_rpc_url)?;

    let wallet = LocalWallet::from_str(&privkey)?;
    let stylus_client = Arc::new(SignerMiddleware::new(
        stylus_provider,
        wallet.with_chain_id(23011913 as u64),
    ));

    let history_prover = HistoryProver::new(address, stylus_client.clone());
    let mut multicall = Multicall::new(stylus_client.clone(), Some(MULTICALL_ADDRESS)).await?;

    loop{
        let batch_size = 50;

        let block_calls = (0..batch_size).map(|index| mainnet_provider.get_block(start_block_number - index));
        let blocks = futures::future::try_join_all(block_calls).await?;

        multicall.clear_calls();

        blocks
            .iter()
            .map(|potential_block| potential_block.as_ref().unwrap())
            .map(|block| get_header(&block))
            .map(|header| {
                let mut data = vec![];
                header.encode(&mut data);
                history_prover.verify_execution_payload_header(data.into())
            })
            .for_each(|call| { multicall.add_call(call, false); });

        let tx = multicall.send().await?;
        println!("{} to {}: {}", start_block_number, start_block_number - (batch_size - 1), tx.tx_hash());
        tx.await?;

        start_block_number = start_block_number - batch_size;
    }
}


fn main() {
    async_main().unwrap();
}
