// Allow `cargo stylus export-abi` to generate a main function.
#![cfg_attr(not(feature = "export-abi"), no_main)]
extern crate alloc;


/// Use an efficient WASM allocator.
#[global_allocator]
static ALLOC: mini_alloc::MiniAlloc = mini_alloc::MiniAlloc::INIT;

use stylus_sdk::{abi::Bytes, alloy_primitives::{U256, FixedBytes, keccak256},  alloy_sol_types::sol, evm,  prelude::*};
use alloy_rlp::{Decodable};


sol! {
    event BlockHashSet(uint256 indexed block_number, bytes indexed block_hash);

    error HashProvidedDifferentThanBlockHash();
}

sol_storage! {
    #[entrypoint]
    pub struct HistoryProver {
        mapping(uint256 => bytes32) block_hash;
    }
}

pub enum ProverError {
    HashProvidedDifferentThanBlockHash,
}

impl From<ProverError> for Vec<u8> {
    fn from(err: ProverError) -> Vec<u8> {
        match err {
            ProverError::HashProvidedDifferentThanBlockHash => b"Hash of pre-image is different than stored block_hash".to_vec(),
        }
    }
}


pub struct Header {
    /// The Keccak 256-bit hash of the parent
    /// block’s header, in its entirety; formally Hp.
    pub parent_hash: [u8;32],
    /// The Keccak 256-bit hash of the ommers list portion of this block; formally Ho.
    pub ommers_hash: [u8;32],
    /// The 160-bit address to which all fees collected from the successful mining of this block
    /// be transferred; formally Hc.
    pub beneficiary: [u8;20],
    /// The Keccak 256-bit hash of the root node of the state trie, after all transactions are
    /// executed and finalisations applied; formally Hr.
    pub state_root: [u8;32],
    /// The Keccak 256-bit hash of the root node of the trie structure populated with each
    /// transaction in the transactions list portion of the block; formally Ht.
    pub transactions_root: [u8;32],
    /// The Keccak 256-bit hash of the root node of the trie structure populated with the receipts
    /// of each transaction in the transactions list portion of the block; formally He.
    pub receipts_root: [u8;32],
    /// The Bloom filter composed from indexable information (logger address and log topics)
    /// contained in each log entry from the receipt of each transaction in the transactions list;
    /// formally Hb.
    pub logs_bloom: [u8;256],
    /// A scalar value corresponding to the difficulty level of this block. This can be calculated
    /// from the previous block’s difficulty level and the timestamp; formally Hd.
    pub difficulty: u64,
    /// A scalar value equal to the number of ancestor blocks. The genesis block has a number of
    /// zero; formally Hi.
    pub number: u64,    
}

impl Decodable for Header {
    fn decode(buf: &mut &[u8]) -> alloy_rlp::Result<Self> {
   
        let rlp_head = alloy_rlp::Header::decode(buf)?;
        if !rlp_head.list {
            return Err(alloy_rlp::Error::UnexpectedString);
        }

        let this = Self {
            parent_hash: Decodable::decode(buf)?,
            ommers_hash: Decodable::decode(buf)?,
            beneficiary: Decodable::decode(buf)?,
            state_root: Decodable::decode(buf)?,
            transactions_root: Decodable::decode(buf)?,
            receipts_root: Decodable::decode(buf)?,
            logs_bloom: Decodable::decode(buf)?,
            difficulty: u64::decode(buf)?,
            number: u64::decode(buf)?,
        };

        Ok(this)
    }
}



#[external]
impl HistoryProver {

    pub fn set_block_hash(&mut self, block_number: U256, block_hash:FixedBytes<32>)-> Result<(), Vec<u8>> {
        let mut new_block_hash = self.block_hash.setter(block_number);
        new_block_hash.set(block_hash);
        
        let block_hash: [u8;32] = (block_hash.as_slice()[0..32]).try_into().unwrap();
        evm::log(BlockHashSet { block_number, block_hash });

        Ok(())
    }


    pub fn verify_execution_payload_header(&mut self, execution_payload_header: Bytes) -> Result<(), Vec<u8>>{

        let header: Header = Header::decode(&mut execution_payload_header.as_slice()).unwrap();
    
        let parent_hash = header.parent_hash;
        let block_number = U256::from(header.number);
    
        let block_hash  = self.block_hash.get(block_number); 
    
        let hash_header = keccak256(execution_payload_header);
    
        if hash_header != block_hash{
            return Err(ProverError::HashProvidedDifferentThanBlockHash.into())
        }
    
        if block_number == U256::from(0){
            return Ok(())
        }

        let _ = self.set_block_hash(block_number - U256::from(1), parent_hash.into());

        Ok(())
    }
   
}


