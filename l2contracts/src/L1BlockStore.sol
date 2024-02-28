// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract L1BlockStore {
    bytes32 public hash;
    uint256 public number;

    event L1BlockSet(bytes32 indexed hash, uint256 indexed number);

    constructor() {
      _update();
    }

    function update() external {
      _update();
    }

    function _update() internal {
      uint256 _number = block.number;
      bytes32 _hash = blockhash(_number);

      hash = _hash;
      number = _number;

      emit L1BlockSet(_hash, _number);
    }
}
