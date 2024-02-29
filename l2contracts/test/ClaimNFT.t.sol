// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import { ClaimNFT } from "../src/ClaimNFT.sol";

contract ClaimNFTTest is Test {
    ClaimNFT private claimer;

    function setUp() public {
        // Deploy NFT contract
      claimer = new ClaimNFT(0xDf859c81287DD1aAcA02d3F56Eaa4dD3C5615EA3);
    }

    function test_claimValidBlock() public {
      bytes memory blockHeader = hex"";

      bytes32 l3StateRoot = 0x5e54e495fdc629af23f7077d2c6434b1c0041f1dc9c36bf38f80e9826ae21f2a;

      bytes[] memory l3StateProof = new bytes[](6);
      l3StateProof[0] = hex"";
      l3StateProof[1] = hex"";
      l3StateProof[2] = hex"";
      l3StateProof[3] = hex"";
      l3StateProof[4] = hex"";
      l3StateProof[5] = hex"";

      bytes[] memory historyProverStorageProof = new bytes[](3);
      historyProverStorageProof[0] = hex"";
      historyProverStorageProof[1] = hex"";
      historyProverStorageProof[2] = hex"";

      bytes[] memory txProof = new bytes[](2);
      txProof[0] = hex"";
      txProof[1] = hex"";

      bytes memory txIndex = hex"";

      /*
      claimer.claim(
        blockHeader,
        txIndex,
        l3StateRoot,
        l3StateProof,
        historyProverStorageProof,
        txProof
      );
      */
    }
}
