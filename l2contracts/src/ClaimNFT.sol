// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {MPT} from "../libs/MPT.sol";
import {StorageVerifier} from "../libs/StorageVerifier.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract ClaimNFT is StorageVerifier {
    using ECDSA for bytes32;
    using ECDSA for bytes;

    function claim(bytes memory blockHeader) {
        uint blockNumber = 0;

        this.verifyL3State(
            blockNumber,
            blockHash,
            signature,
            blockHeader.storageRoot,
            stateProof,
            storageProof
        );
    }

    function verifyTransactionInclusion(
        bytes[] memory txProof,
        bytes32 txRoot,
        uint txIndex
    ) public {
        bytes memory tx = MPT.verifyLeaf(txRoot, txIndex, txProof);
    }

    function verifyL3State(
        uint blockNumber,
        bytes32 blockHash,
        bytes memory signature,
        bytes32 storageRoot,
        bytes[] memory stateProof,
        bytes[] memory storageProof
    ) public {
        //bytes32 message = abi.encode(_msgSender()).toEthSignedMessageHash();
        //address owner = message.recover(signature);

        address HistoryProverContractAddress = 0xeF1a89cbfAbE59397FfdA11Fc5DF293E9bC5Db90; // address of HistoryProver on L3

        MPT.Account memory historyContract = MPT.Account({
            accountAddress: HistoryProverContractAddress,
            balance: 0,
            nonce: 1,
            storageRoot: storageRoot,
            codeHash: 0xfc1ea81db44e2de921b958dc92da921a18968ff3f3465bd475fb86dd1af03986 // HASH of HistoryProver on L3
        });

        // Expectation: the slot contains the block hash of block Number
        MPT.StorageSlot memory slot = MPT.StorageSlot({
            position: uint256(keccak256(abi.encode(blockNumber, uint256(0)))),
            value: uint256(uint160(blockHash))
        });

        // https://github.com/OffchainLabs/nitro-contracts/blob/90037b996509312ef1addb3f9352457b8a99d6a6/src/bridge/AbsOutbox.sol#L32

        bytes32 l3StateRoot;

        // Then verify the proof
        _verifyStorage(
            l3StateRoot,
            historyContract,
            slot,
            stateProof,
            storageProof
        );
    }
}
