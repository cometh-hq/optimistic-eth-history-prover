// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/console.sol";
import {MPT} from "./libs/MPT.sol";
import {StorageVerifier} from "./libs/StorageVerifier.sol";
import {TransactionHasher} from "./libs/TransactionHasher.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {RLPReader} from "./libs/RLPReader.sol";

contract ClaimNFT is StorageVerifier {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    address immutable public historyProverAddress;

    struct TxProof {
      // L1 Block header that contains the transaction signed by msg.sender
      bytes l1BlockHeader;
      // index of the transaction signed by msg.sender inside the block
      bytes txIndex;
      // Proof of the history contract storage layout on L3
      bytes[] l3StateProof;
      // Proof of the storage slot of the L1 block hash in the history prover contract
      bytes[] historyContractStorageProof;
      // Proof of inclusion of the transaction signed by msg.sender inside the L1 block
      bytes[] txProof;
    }

    constructor(address _historyProverAddress) {
      historyProverAddress = _historyProverAddress;
    }

    function claim(
      // State root of the L3 where history prover contract is deployed
      bytes32 l3StateRoot,
      TxProof memory firstTxProof,
      TxProof memory secondTxProof
    ) external {
      (address firstTxSigner, uint256 firstTxNonce, uint256 firstTxBlockNumber) =
        verifyTransaction(l3StateRoot, firstTxProof);
      (address secondTxSigner, uint256 secondTxNonce, uint256 secondTxBlockNumber) =
        verifyTransaction(l3StateRoot, firstTxProof);
    }

    function verifyTransaction(bytes32 l3StateRoot, TxProof memory txProof) internal returns (address txSigner, uint256 txNonce, uint256 l1BlockNumber) {
      RLPReader.RLPItem[] memory l1Header = txProof.l1BlockHeader.toRlpItem().toList();
      l1BlockNumber = l1Header[8].toUint();
      bytes32 l1BlockHash = keccak256(txProof.l1BlockHeader);

      verifyL3State(
        l1BlockNumber,
        l1BlockHash,
        l3StateRoot,
        txProof.l3StateProof,
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
    ) internal returns (bytes memory transaction) {
        transaction = MPT.verifyLeaf(txRoot, txIndex, txProof);
    }

    function verifyL3State(
        uint blockNumber,
        bytes32 blockHash,
        // FIXME: Find l3 state root from Rollup contract
        bytes32 l3StateRoot,
        bytes[] memory stateProof,
        bytes[] memory storageProof
    ) internal {
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
