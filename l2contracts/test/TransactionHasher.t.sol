// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import { TransactionHasher } from "../src/libs/TransactionHasher.sol";

contract TransactionHasherTest is Test {
    function setUp() public { }

    function test_testLegacyTxHash() public {
      bytes memory rawTx = hex"f86e158512bfb19e608301f8dc94c083e9947cf02b8ffc7d3090ae9aea72df98fd4789056bc75e2d63100000801ca0a254fe085f721c2abe00a2cd244110bfc0df5f4f25461c85d8ab75ebac11eb10a030b7835ba481955b20193a703ebc5fdffeab081d63117199040cdf5a91c68765";
      bytes32 txHash = 0xdc4e822023e51d12671021423124451a45acf48b4308ac9f64b0226e267a0f2d;

      (bytes32 hash, address signer) = TransactionHasher.hash(rawTx);

      assertEq(hash, txHash);
      assertEq(signer, 0x39fA8c5f2793459D6622857E7D9FbB4BD91766d3);
    }

    function test_testLegacy155TxHash() public {
      bytes memory rawTx = hex"f86c098504a817c800825208943535353535353535353535353535353535353535880de0b6b3a76400008025a028ef61340bd939bc2195fe537567866003e1a15d3c71ff63e1590620aa636276a067cbe9d8997f761aecb703304b3800ccf555c9f3dc64214b297fb1966a3b6d83";
      bytes32 txHash = 0xdaf5a779ae972f972197303d7b574746c7ef83eadac0f2791ad23db92e4c8e53;

      (bytes32 hash, address signer) = TransactionHasher.hash(rawTx);

      assertEq(hash, txHash);
      assertEq(signer, 0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F);
    }
}
