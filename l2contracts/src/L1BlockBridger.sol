// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "nitro-contracts/bridge/IInbox.sol";
import { Ownable } from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract L1BlockBridger is Ownable {
    IInbox public inbox;
    address public destination;

    event L1BlockSent(bytes32 indexed hash, uint256 indexed number);
    event SetDestination(address destination);

    constructor(IInbox _inbox) Ownable(msg.sender) {
      inbox = _inbox;
    }

    function setDestination(address _destination) external onlyOwner {
      destination = _destination;
      emit SetDestination(_destination);
    }

    function update() payable external {
      address _destination = destination;
      require(destination != address(0), "no destination set");

      uint256 _number = block.number - 1;
      bytes32 _hash = blockhash(_number);

      IInbox _inbox = inbox;

      emit L1BlockSent(_hash, _number);
    }
}
