// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/console.sol";
import {MPT} from "./libs/MPT.sol";
import {StorageVerifier} from "./libs/StorageVerifier.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {RLPReader} from "./libs/RLPReader.sol";

contract ClaimNFT is StorageVerifier {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    address immutable public historyProverAddress;

    constructor(address _historyProverAddress) {
      historyProverAddress = _historyProverAddress;
    }

    function claim(
      // L1 Block header that contains the transaction signed by msg.sender
      bytes memory l1BlockHeader,
      // index of the transaction signed by msg.sender inside the block
      bytes memory txIndex,
      // State root of the L3 where history prover contract is deployed
      bytes32 l3StateRoot,
      // Proof of the history contract storage layout on L3
      bytes[] memory l3StateProof,
      // Proof of the storage slot of the L1 block hash in the history prover contract
      bytes[] memory historyContractStorageProof,
      // Proof of inclusion of the transaction signed by msg.sender inside the L1 block
      bytes[] memory txProof
    ) external {
      RLPReader.RLPItem[] memory l1Header = l1BlockHeader.toRlpItem().toList();

      uint256 l1BlockNumber = l1Header[8].toUint();
      bytes32 txRoot = bytes32(l1Header[4].toUint());

      bytes32 l1BlockHash = keccak256(l1BlockHeader);

      verifyL3State(
        l1BlockNumber,
        l1BlockHash,
        l3StateRoot,
        l3StateProof,
        historyContractStorageProof
      );

      bytes memory transaction = verifyTransactionInclusion(
        txRoot,
        txProof, 
        txIndex
      );

      console.logBytes(transaction);
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
