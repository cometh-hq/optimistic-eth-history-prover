// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {MPT} from "./libs/MPT.sol";
import {TransactionHasher} from "./libs/TransactionHasher.sol";
import {RLPReader} from "./libs/RLPReader.sol";
import {ETHDenverBuilder} from "./ETHDenverBuilder.sol";

contract ClaimNFT {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    address immutable public historyProverAddress;

    ETHDenverBuilder public nft;

    uint256 public minL1Block;
    uint256 public maxL1Block;

    // current maximum
    uint256 public maxTxCount;

    struct TxProof {
      // L1 Block header that contains the transaction signed by msg.sender
      bytes l1BlockHeader;
      // index of the transaction signed by msg.sender inside the block
      bytes txIndex;
      // Proof of the storage slot of the L1 block hash in the history prover contract
      bytes[] historyContractStorageProof;
      // Proof of inclusion of the transaction signed by msg.sender inside the L1 block
      bytes[] txProof;
    }

    event ClaimedNFT(address indexed claimer, uint256 txCount);

    error WrongTxOrder(uint256 firstBlockNumber, uint256 secondTxBlockNumber);
    error WrongTxSigner(address firstSigner, address secondSigner);
    error NotSenderTransaction(address signer);
    error TxCountTooLow(uint256 max, uint256 value);
    error InvalidRangeTx(uint256 blockNumber);

    constructor(
      ETHDenverBuilder _nft,
      address _historyProverAddress,
      uint256 _minL1Block,
      uint256 _maxL1Block
    ) {
      nft = _nft;
      historyProverAddress = _historyProverAddress;

      minL1Block = _minL1Block;
      maxL1Block = _maxL1Block;

      maxTxCount = 0;
    }

    function claim(
      // State root of the L3 where history prover contract is deployed
      bytes32 l3StateRoot,
      bytes[] memory l3StateProof,
      TxProof memory firstTxProof,
      TxProof memory secondTxProof
    ) external {
      (address firstTxSigner, uint256 firstTxNonce, uint256 firstTxBlockNumber) =
        verifyTransaction(l3StateRoot, l3StateProof, firstTxProof);

      (address secondTxSigner, uint256 secondTxNonce, uint256 secondTxBlockNumber) =
        verifyTransaction(l3StateRoot, l3StateProof, secondTxProof);

      if (firstTxSigner != secondTxSigner) {
        revert WrongTxSigner(firstTxSigner, secondTxSigner);
      }

      if (firstTxSigner != msg.sender) {
        revert NotSenderTransaction(firstTxSigner);
      }
      {
        uint256 _max = maxL1Block;
        uint256 _min = minL1Block;
        if (firstTxBlockNumber > _max || firstTxBlockNumber < _min) {
          revert InvalidRangeTx(firstTxBlockNumber);
        }
        if (secondTxBlockNumber > _max || secondTxBlockNumber < _min) {
          revert InvalidRangeTx(firstTxBlockNumber);
        }
      }

      uint256 txCount;
      if (firstTxBlockNumber > secondTxBlockNumber) {
        txCount = firstTxNonce - secondTxNonce;
      } else {
        txCount = secondTxNonce - firstTxNonce;
      }

      if (txCount <= maxTxCount) {
        revert TxCountTooLow(maxTxCount, txCount);
      }

      maxTxCount = txCount;
      nft.transferOG(msg.sender);
      emit ClaimedNFT(msg.sender, txCount);
    }

    function verifyTransaction(bytes32 l3StateRoot, bytes[] memory l3StateProof, TxProof memory txProof) internal view returns (address txSigner, uint256 txNonce, uint256 l1BlockNumber) {
      RLPReader.RLPItem[] memory l1Header = txProof.l1BlockHeader.toRlpItem().toList();
      l1BlockNumber = l1Header[8].toUint();

      bytes32 l1BlockHash = keccak256(txProof.l1BlockHeader);

      verifyL3State(
        l1BlockNumber,
        l1BlockHash,
        l3StateRoot,
        l3StateProof,
        txProof.historyContractStorageProof
      );

      bytes32 txRoot = bytes32(l1Header[4].toUint());
      bytes memory transaction = verifyTransactionInclusion(txRoot, txProof.txProof, txProof.txIndex);
      bytes32 txHash;
      (txHash, txSigner, txNonce) = TransactionHasher.hash(transaction);
    }

    function verifyTransactionInclusion(
        bytes32 txRoot,
        bytes[] memory txProof,
        bytes memory txIndex
    ) internal pure returns (bytes memory transaction) {
        transaction = MPT.verifyLeaf(txRoot, txIndex, txProof);
    }

    function verifyL3State(
        uint blockNumber,
        bytes32 blockHash,
        // FIXME: Find l3 state root from Rollup contract
        bytes32 l3StateRoot,
        bytes[] memory stateProof,
        bytes[] memory storageProof
    ) internal view {
        bytes memory l3StateTrieKey = abi.encode(keccak256(abi.encodePacked(historyProverAddress)));

        bytes memory accountBytes = MPT.verifyLeaf(l3StateRoot, l3StateTrieKey, stateProof);
        RLPReader.RLPItem[] memory account = accountBytes.toRlpItem().toList();

        bytes32 storageRoot = bytes32(account[2].toUint());

        // Expectation: the slot contains the block hash of block Number
        MPT.StorageSlot memory slot = MPT.StorageSlot({
            position: uint256(keccak256(abi.encode(blockNumber, uint256(0)))),
            value: uint256(blockHash)
        });

        if (!MPT.verifyStorageSlot(storageRoot, slot, storageProof)) {
          require(false, "storage proof invalid");
        }

    }
}
