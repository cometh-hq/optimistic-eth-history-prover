
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {L1BlockStore} from "../src/L1BlockStore.sol";

contract L1BlockStoreTest is Test {
    L1BlockStore public store;

    function setUp() public {
        store = new L1BlockStore();
    }

    function test_update() public {
    }
}
