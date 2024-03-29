// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract ETHDenverBuilder is ERC721, AccessControl {
    bytes32 public constant CLAIMER_ROLE = keccak256("CLAIMER_ROLE");

    constructor() ERC721("ETHDenverBuilder", "BUIDL") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _safeMint(address(this), 0);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://optimistic-eth-history-prover.vercel.app/nft/storylus-demo-nft.png";
    }

    function transferOG(address recipient) public onlyRole(CLAIMER_ROLE) {
        _update(recipient, 0, address(0));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
