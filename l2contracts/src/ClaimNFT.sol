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

    function claim(
      bytes memory l1BlockHeader,
      bytes[] memory l3StateProof,
      bytes[] memory historyContractStorageProof
    ) external {
      RLPReader.RLPItem[] memory l1Header = l1BlockHeader.toRlpItem().toList();

      uint256 l1BlockNumber = l1Header[8].toUint();
      bytes32 l1BlockHash = keccak256(l1BlockHeader);

      verifyL3State(
        l1BlockNumber,
        l1BlockHash,
        l3StateProof,
        historyContractStorageProof
      );
    }

    function verifyTransactionInclusion(
        bytes[] memory txProof,
        bytes32 txRoot,
        uint txIndex
    ) internal {
        bytes memory transaction = MPT.verifyLeaf(txRoot, txIndex, txProof);
    }

    function verifyL3State(
        uint blockNumber,
        bytes32 blockHash,
        bytes[] memory stateProof,
        bytes[] memory storageProof
    ) internal {
      // address of HistoryProver on L3
        address HistoryProverContractAddress = 0xeF1a89cbfAbE59397FfdA11Fc5DF293E9bC5Db90; 
        uint256 l3StateTrieKey = uint256(keccak256(abi.encodePacked(HistoryProverContractAddress)));

        // https://github.com/OffchainLabs/nitro-contracts/blob/90037b996509312ef1addb3f9352457b8a99d6a6/src/bridge/AbsOutbox.sol#L32
        bytes32 l3StateRoot;

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
