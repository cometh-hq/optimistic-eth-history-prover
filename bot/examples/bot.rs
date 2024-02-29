use ethers::{
    middleware::SignerMiddleware,
    prelude::abigen,
    providers::{Http, Middleware, Provider},
    signers::{LocalWallet, Signer},
    types::{Address},
};
use std::str::FromStr;
use std::sync::Arc;
use reth::primitives::{Header, U256, Bytes};
use alloy_rlp::{Encodable};

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

    //latest block indexed
    let mut block_number = 5387881;

    loop{
        let rpc_mainnet = "".to_string();
        let provider = Provider::<Http>::try_from(rpc_mainnet)?;
        let client_mainnet = Arc::new(SignerMiddleware::new(
            provider,
            wallet.clone().with_chain_id(chain_id),
        ));

        let block = client_mainnet.get_block(block_number).await?.unwrap();

        let blob_gas_used = block.blob_gas_used.map(|x| x.low_u64() );
        let base_fee_per_gas = block.base_fee_per_gas.map(|x| x.low_u64() );
        let excess_blob_gas = block.excess_blob_gas.map(|x| x.low_u64() );
        let timestamp = block.timestamp.low_u64();

        let mut difficulty_bytes:Vec<u8> = vec![0; 32];

        block.difficulty.to_little_endian(difficulty_bytes.as_mut_slice());
        let difficulty = U256::from_le_slice(difficulty_bytes.as_slice());
   

        let header = Header {
            parent_hash: block.parent_hash.as_fixed_bytes().into(),
            ommers_hash: block.uncles_hash.as_fixed_bytes().into(),
            beneficiary: block.author.unwrap().to_fixed_bytes().into(),
            state_root: block.state_root.as_fixed_bytes().into(),
            transactions_root: block.transactions_root.as_fixed_bytes().into(),
            receipts_root: block.receipts_root.as_fixed_bytes().into(),
            withdrawals_root:block.withdrawals_root.map(|x| x.as_fixed_bytes().into()),
            logs_bloom: block.logs_bloom.unwrap().as_fixed_bytes().into(),
            difficulty:difficulty,
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
        };

        let mut data = vec![];
        header.encode(&mut data);


        let second_tx = history_prover.verify_execution_payload_header(data.into()).send().await?.await?;
    
        println!("Block Number indexed: {:?}", block_number);
        block_number -= 1;
    

        if block_number == 5348474 {
            println!("Iteration done");
            break;
        } 
    }

    Ok(())
}


