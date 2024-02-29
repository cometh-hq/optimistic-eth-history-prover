// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/console.sol";
import {MPT} from "./MPT.sol";

abstract contract StorageVerifier {
    error InvalidStateProof();
    error InvalidStorageProof();

    error Debug(bytes32 p);

    function _verifyStorage(
        bytes32 root,
        MPT.Account memory contractAccount,
        MPT.StorageSlot memory contractSlot,
        bytes[] memory stateProof,
        bytes[] memory storageProof
    ) internal pure {
        if (!MPT.verifyAccount(root, contractAccount, stateProof)) {
            revert InvalidStateProof();
        }
        if (
            !MPT.verifyStorageSlot(
                contractAccount.storageRoot,
                contractSlot,
                storageProof
            )
        ) {
            revert InvalidStorageProof();
        }
    }
}
