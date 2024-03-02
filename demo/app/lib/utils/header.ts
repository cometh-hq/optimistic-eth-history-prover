import { ethers } from 'ethers';

const { toBeArray } = ethers;

export function encodeHeader(block: any): string {
  /*
  ParentHash  common.Hash    `json:"parentHash"       gencodec:"required"`
	UncleHash   common.Hash    `json:"sha3Uncles"       gencodec:"required"`
	Coinbase    common.Address `json:"miner"`
	Root        common.Hash    `json:"stateRoot"        gencodec:"required"`
	TxHash      common.Hash    `json:"transactionsRoot" gencodec:"required"`
	ReceiptHash common.Hash    `json:"receiptsRoot"     gencodec:"required"`
	Bloom       Bloom          `json:"logsBloom"        gencodec:"required"`
	Difficulty  *big.Int       `json:"difficulty"       gencodec:"required"`
	Number      *big.Int       `json:"number"           gencodec:"required"`
	GasLimit    uint64         `json:"gasLimit"         gencodec:"required"`
	GasUsed     uint64         `json:"gasUsed"          gencodec:"required"`
	Time        uint64         `json:"timestamp"        gencodec:"required"`
	Extra       []byte         `json:"extraData"        gencodec:"required"`
	MixDigest   common.Hash    `json:"mixHash"`
	Nonce       BlockNonce     `json:"nonce"`

	// BaseFee was added by EIP-1559 and is ignored in legacy headers.
	BaseFee *big.Int `json:"baseFeePerGas" rlp:"optional"`

	// WithdrawalsHash was added by EIP-4895 and is ignored in legacy headers.
	WithdrawalsHash *common.Hash `json:"withdrawalsRoot" rlp:"optional"`

	// BlobGasUsed was added by EIP-4844 and is ignored in legacy headers.
	BlobGasUsed *uint64 `json:"blobGasUsed" rlp:"optional"`

	// ExcessBlobGas was added by EIP-4844 and is ignored in legacy headers.
	ExcessBlobGas *uint64 `json:"excessBlobGas" rlp:"optional"`

	// ParentBeaconRoot was added by EIP-4788 and is ignored in legacy headers.
	ParentBeaconRoot *common.Hash `json:"parentBeaconBlockRoot" rlp:"optional"`
  */
  const fields = [
    block.parentHash,
    block.sha3Uncles,
    block.miner,
    block.stateRoot,
    block.transactionsRoot,
    block.receiptsRoot,
    block.logsBloom,
    toBeArray(block.difficulty),
    toBeArray(block.number),
    toBeArray(block.gasLimit),
    toBeArray(block.gasUsed),
    toBeArray(block.timestamp),
    block.extraData,
    block.mixHash,
    block.nonce
  ];
  if (block.baseFeePerGas) fields.push(toBeArray(block.baseFeePerGas)); 
  if (block.withdrawalsRoot) fields.push(block.withdrawalsRoot);
  if (block.blobGasUsed) {
    fields.push(toBeArray(block.blobGasUsed));
    fields.push(toBeArray(block.excessBlobGas));
  }
  if (block.parentBeaconBlockRoot) fields.push(block.parentBeaconBlockRoot);

  const result = ethers.encodeRlp(fields);
  if (block.hash) {
    const hash = ethers.keccak256(result);
    if (hash !== block.hash) throw new Error('invalid hash');
  }
  return result;
}
