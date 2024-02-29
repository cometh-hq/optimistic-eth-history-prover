// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {RLPReader} from "./RLPReader.sol";

library MPT {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    error InvalidProof(uint256 index);
    error InvalidAccount();

    struct Account {
        address accountAddress;
        uint256 nonce;
        uint256 balance;
        bytes32 storageRoot;
        bytes32 codeHash;
    }

    struct StorageSlot {
        uint256 position;
        uint256 value;
    }

    // [nonce,balance,storageRoot,codeHash]
    function verifyAccount(
        bytes32 root,
        Account memory account,
        bytes[] memory proof
    ) internal pure returns (bool) {
        uint256 key = uint256(
            keccak256(abi.encodePacked(account.accountAddress))
        );

        bytes memory leaf = verifyLeaf(root, abi.encode(key), proof);

        RLPReader.RLPItem[] memory decoded = leaf.toRlpItem().toList();

        if (decoded.length != 4) revert InvalidAccount();
        if (decoded[0].toUint() != account.nonce) return false;
        if (decoded[1].toUint() != account.balance) return false;
        if (decoded[2].toUint() != uint256(account.storageRoot)) return false;
        if (decoded[3].toUint() != uint256(account.codeHash)) return false;

        return true;
    }

    function verifyStorageSlot(
        bytes32 root,
        StorageSlot memory slot,
        bytes[] memory proof
    ) internal pure returns (bool) {
        bytes memory key = abi.encode(uint256(keccak256(abi.encode(slot.position))));

        bytes memory leaf = verifyLeaf(root, key, proof);

        return slot.value == leaf.toRlpItem().toUint();
    }

    function verifyLeaf(
        bytes32 root,
        bytes memory key,
        bytes[] memory proof
    ) internal pure returns (bytes memory result) {
        uint8 nibble = 0;
        RLPReader.RLPItem[] memory node;
        for (uint256 index = 0; index < proof.length; ++index) {
            if (keccak256(proof[index]) != root) revert InvalidProof(index);

            node = proof[index].toRlpItem().toList();
            if (node.length == 17) {
                //uint256 keyNibble = (key >> (252 - (nibble++ * 4))) & 0xf;
                uint8 keyNibble = (uint8(key[nibble++ / 2]) >> (4 * (1-(nibble % 2)))) & 0xf;
                root = bytes32(node[keyNibble].toUintStrict());
            } else if (node.length == 2) {
                bytes memory prefix = node[0].toBytes();

                bool isExtension;
                (isExtension, nibble) = checkEncodedPath(
                    prefix,
                    key,
                    nibble,
                    index
                );

                if (isExtension) {
                    root = bytes32(node[1].toUintStrict());
                } else {
                    break;
                }
            }
        }

        if (nibble != key.length * 2) revert InvalidProof(proof.length - 1);
        return node[1].toBytes();
    }

    /*
        hex char    bits    |    node type partial     path length
      ----------------------------------------------------------
        0        0000    |       extension              even
        1        0001    |       extension              odd
        3        0011    |   terminating (leaf)         odd
        2        0010    |   terminating (leaf)         even
  */
    function checkEncodedPath(
        bytes memory prefix,
        bytes memory key,
        uint8 nibble,
        uint256 index
    ) private pure returns (bool, uint8) {
        uint8 nodeType = uint8(prefix[0] >> 4);

        // odd cases
        if (nodeType & 0x1 != 0) {
            //uint256 keyNibble = (key >> (252 - (nibble++ * 4))) & 0xf;
            uint8 keyNibble = (uint8(key[nibble++ / 2]) >> (4 * (1-(nibble % 2)))) & 0xf;

            uint256 prefixNibble = uint8(prefix[0]) & 0xf;

            if (prefixNibble != keyNibble) revert InvalidProof(index);
        }

        uint256 prefixLen = prefix.length;

        assert(nibble % 2 == 0);
        for (uint256 i = 1; i < prefixLen; ++i) {
            uint8 prefixByte = uint8(prefix[i]);
            //uint256 keyByte = (key >> (248 - (nibble * 4))) & 0xff;
            uint8 keyByte = uint8(key[nibble / 2]);

            if (prefixByte != keyByte) revert InvalidProof(index);

            nibble += 2;
        }

        // return true if node is an extension and we should continue traveling the trie
        // also returns the new nibble count, for bookkeeping
        return (nodeType & 0x2 == 0, nibble);
    }
}
