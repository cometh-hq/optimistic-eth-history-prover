// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {ETHDenverBuilder} from "../src/ETHDenverBuilder.sol";
import {ClaimNFT} from "../src/ClaimNFT.sol";

contract DeployScript is Script {
  function run() external {
    vm.startBroadcast();

    ETHDenverBuilder nft = new ETHDenverBuilder();
    ClaimNFT claimer = new ClaimNFT(nft, 0x9DFBC5488CDE99Bfd45a541C7E04988C2c846731, 5348475, 5387881);
    nft.grantRole(nft.CLAIMER_ROLE(), address(claimer));

    vm.stopBroadcast();
  }
}
