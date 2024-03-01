// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/console.sol";
import {RLPReader} from "./RLPReader.sol";
import {RLPEncode} from "./RLPEncode.sol";

library TransactionHasher {
  using RLPReader for bytes;
  using RLPReader for RLPReader.RLPItem;
  using RLPEncode for bytes[];
  using RLPEncode for bytes;

  error InvalidTransactionType(bytes1 txType);

  function hash(bytes memory rawTx) internal pure returns (bytes32 hashed, address signer, uint256 nonce) {
    if (rawTx[0] >= 0xc0) {
       return hashLegacy(rawTx);
    } else if (rawTx[0] == 0x01) {
       return hash2930(rawTx);
    } else if (rawTx[0] == 0x02) {
       return hash1559(rawTx);
    } else if (rawTx[0] == 0x03) {
       return hash4844(rawTx);
    } else {
      revert InvalidTransactionType(rawTx[0]);
    }
  }

  function hash4844(bytes memory rawTx) internal pure returns (bytes32 hashed, address signer, uint256 nonce) {
    // BLOB_TX_TYPE || rlp([chain_id, nonce, max_priority_fee_per_gas, max_fee_per_gas, gas_limit, to, value, data, access_list, max_fee_per_blob_gas, blob_versioned_hashes])
    RLPReader.RLPItem[] memory transaction = rawTx.toRlpItemWithOffset(1).toList();

    bytes[] memory toEncode = new bytes[](11);
    for (uint i = 0; i < 11; ++i) {
      toEncode[i] = transaction[i].toRlpBytes();
    }

    bytes memory toHash = abi.encodePacked(uint8(3), RLPEncode.encodeList(toEncode));
    hashed = keccak256(toHash);

    uint256 v = 27 + transaction[11].toUint();
    bytes32 r = bytes32(transaction[12].toUint());
    bytes32 s = bytes32(transaction[13].toUint());

    signer = ecrecover(hashed, uint8(v), r, s);
    nonce = transaction[1].toUint();
  }

  function hash1559(bytes memory rawTx) internal pure returns (bytes32 hashed, address signer, uint256 nonce) {
    // 0x02 || rlp([chain_id, nonce, max_priority_fee_per_gas, max_fee_per_gas, gas_limit, destination, amount, data, access_list])
    RLPReader.RLPItem[] memory transaction = rawTx.toRlpItemWithOffset(1).toList();

    bytes[] memory toEncode = new bytes[](9);
    for (uint i = 0; i < 9; ++i) {
      toEncode[i] = transaction[i].toRlpBytes();
    }

    bytes memory toHash = abi.encodePacked(uint8(2), RLPEncode.encodeList(toEncode));
    hashed = keccak256(toHash);

    uint256 v = 27 + transaction[9].toUint();
    bytes32 r = bytes32(transaction[10].toUint());
    bytes32 s = bytes32(transaction[11].toUint());

    signer = ecrecover(hashed, uint8(v), r, s);
    nonce = transaction[1].toUint();
  }

  function hash2930(bytes memory rawTx) internal pure returns (bytes32 hashed, address signer, uint256 nonce) {
    // 0x01 || rlp([chainId, nonce, gasPrice, gasLimit, to, value, data, accessList, signatureYParity, signatureR, signatureS]).
    RLPReader.RLPItem[] memory transaction = rawTx.toRlpItemWithOffset(1).toList();

    bytes[] memory toEncode = new bytes[](8);
    for (uint i = 0; i < 8; ++i) {
      toEncode[i] = transaction[i].toRlpBytes();
    }

    bytes memory toHash = abi.encodePacked(uint8(1), RLPEncode.encodeList(toEncode));
    hashed = keccak256(toHash);

    uint256 v = 27 + transaction[8].toUint();
    bytes32 r = bytes32(transaction[9].toUint());
    bytes32 s = bytes32(transaction[10].toUint());

    signer = ecrecover(hashed, uint8(v), r, s);
    nonce = transaction[1].toUint();
  }

  function hashLegacy(bytes memory rawTx) internal pure returns (bytes32 hashed, address signer, uint256 nonce) {
    RLPReader.RLPItem[] memory transaction = rawTx.toRlpItem().toList();

    // (nonce, gasprice, startgas, to, value, data)
    // post EIP-155: (nonce, gasprice, startgas, to, value, data, chainid, 0, 0)

    uint256 v = transaction[6].toUint();
    bytes32 r = bytes32(transaction[7].toUint());
    bytes32 s = bytes32(transaction[8].toUint());

    uint len = 6;
    if (v > 28) { len += 3; }

    bytes[] memory toEncode = new bytes[](len);
    for (uint i = 0; i < 6; ++i) {
      toEncode[i] = transaction[i].toRlpBytes();
    }
    if (v > 28) {
      uint chainId = (v - 35) / 2;
      toEncode[6] = RLPEncode.encodeUint(chainId);
      toEncode[7] = RLPEncode.encodeUint(0);
      toEncode[8] = RLPEncode.encodeUint(0);
      v -= chainId * 2 + 8;
    }

    bytes memory toHash = RLPEncode.encodeList(toEncode);

    hashed = keccak256(toHash);
    signer = ecrecover(hashed, uint8(v), r, s);
    nonce = transaction[0].toUint();
  }
}
