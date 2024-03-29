// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import { TransactionHasher } from "../src/libs/TransactionHasher.sol";

contract TransactionHasherTest is Test {
    function setUp() public { }

    function test_legacyTxHash() public {
      bytes memory rawTx = hex"f86e158512bfb19e608301f8dc94c083e9947cf02b8ffc7d3090ae9aea72df98fd4789056bc75e2d63100000801ca0a254fe085f721c2abe00a2cd244110bfc0df5f4f25461c85d8ab75ebac11eb10a030b7835ba481955b20193a703ebc5fdffeab081d63117199040cdf5a91c68765";
      bytes32 txHash = 0xdc4e822023e51d12671021423124451a45acf48b4308ac9f64b0226e267a0f2d;
      address expectedSigner = 0x39fA8c5f2793459D6622857E7D9FbB4BD91766d3;
      uint256 expectedNonce = 21;

      (bytes32 hash, address signer, uint256 nonce) = TransactionHasher.hash(rawTx);

      assertEq(hash, txHash);
      assertEq(signer, expectedSigner);
      assertEq(nonce, expectedNonce);
    }

    function test_legacy155TxHash() public {
      bytes memory rawTx = hex"f86c098504a817c800825208943535353535353535353535353535353535353535880de0b6b3a76400008025a028ef61340bd939bc2195fe537567866003e1a15d3c71ff63e1590620aa636276a067cbe9d8997f761aecb703304b3800ccf555c9f3dc64214b297fb1966a3b6d83";
      bytes32 txHash = 0xdaf5a779ae972f972197303d7b574746c7ef83eadac0f2791ad23db92e4c8e53;
      address expectedSigner = 0x9d8A62f656a8d1615C1294fd71e9CFb3E4855A4F;
      uint256 expectedNonce = 9;

      (bytes32 hash, address signer, uint256 nonce) = TransactionHasher.hash(rawTx);

      assertEq(hash, txHash);
      assertEq(signer, expectedSigner);
      assertEq(nonce, expectedNonce);
    }

    function test_2930Hash() public {
      bytes memory rawTx = hex"01f8fa800285161e70f60082520894e72fd349164cbf0dd4367102b67d08c16ce4dc0b8080f893f8599400000000000c2e074ec69a0dfb2997ba6c7d2e1ef842a00000000000000000000000000000000000000000000000000000000000000004a00bcad17ecf260d6506c6b97768bdc2acfb6694445d27ffd3f9c1cfbee4a9bd6df7945ffc014343cd971b7eb70732021e26c35b744cc4e1a0000000000000000000000000000000000000000000000000000000000000000101a07a0bbef2d465da9bb68f4fa91ba681248b0408ec3f147f42172f957eec879533a051015e339627f6b7946cc2d4533c0a1c80a1512c34ee185ec3bba07f75b73258";
      bytes32 txHash = 0x43c4fb5469eaa0dca79ba72bafb60a0a6de4df65479453dc0e44171b7c05c1b3;
      address expectedSigner = 0xC2F33f9eb213f986f11b214fcaaDd6F32E23938F;
      uint256 expectedNonce = 2;

      (bytes32 hash, address signer, uint256 nonce) = TransactionHasher.hash(rawTx);

      assertEq(hash, txHash);
      assertEq(signer, expectedSigner);
      assertEq(nonce, expectedNonce);
    }

    function test_1559Hash() public {
      bytes memory rawTx = hex"02f90100800285161e70f600850ba43b740082520894e72fd349164cbf0dd4367102b67d08c16ce4dc0b8080f893f8599400000000000c2e074ec69a0dfb2997ba6c7d2e1ef842a00000000000000000000000000000000000000000000000000000000000000004a00bcad17ecf260d6506c6b97768bdc2acfb6694445d27ffd3f9c1cfbee4a9bd6df7945ffc014343cd971b7eb70732021e26c35b744cc4e1a0000000000000000000000000000000000000000000000000000000000000000101a097ed61e61f04dc335dc338e801f93123e7c880dbfdcf1143344723b41eb152b0a043474be57ca48eb39af35a8f971cfd7638e4cfc94326fd4eb7ff79bf3dda6ef4";
      bytes32 txHash = 0x199e1afa1ca2ac347a659f4ad7bb7b21e54eaff6bedebe0219ae1c1dd1779dc4;
      address expectedSigner = 0xC2F33f9eb213f986f11b214fcaaDd6F32E23938F;
      uint256 expectedNonce = 2;

      (bytes32 hash, address signer, uint256 nonce) = TransactionHasher.hash(rawTx);

      assertEq(hash, txHash);
      assertEq(signer, expectedSigner);
      assertEq(nonce, expectedNonce);
    }

    function test_4844Hash() public {
      bytes memory rawTx = hex"03f9010780028506fc23ac00850ba43b740082520894e72fd349164cbf0dd4367102b67d08c16ce4dc0b8080f893f8599400000000000c2e074ec69a0dfb2997ba6c7d2e1ef842a00000000000000000000000000000000000000000000000000000000000000004a00bcad17ecf260d6506c6b97768bdc2acfb6694445d27ffd3f9c1cfbee4a9bd6df7945ffc014343cd971b7eb70732021e26c35b744cc4e1a000000000000000000000000000000000000000000000000000000000000000018506fc23ac00c080a0faf1924664895657bdaff2cfdf08c22f6092ef095e4593e9689a885f937b37f4a0072f2e573244f0fac97ceccc5082e2de447f7ea1076f23b79584a0a41edba0ae";
      bytes32 txHash = 0x56539f713c502c47935dd17c60910ff9e4048c0b08f6c9fa347287cc3ad71814;
      address expectedSigner = 0xC2F33f9eb213f986f11b214fcaaDd6F32E23938F;
      uint256 expectedNonce = 2;

      (bytes32 hash, address signer, uint256 nonce) = TransactionHasher.hash(rawTx);

      assertEq(hash, txHash);
      assertEq(signer, expectedSigner);
      assertEq(nonce, expectedNonce);
    }
}
