// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "ds-test/test.sol";

import "../Alphabet.sol";
import "../Batcher.sol";

abstract contract Hevm {
  function warp(uint) public virtual;
}

contract User {
  Alphabet alphabet;

  uint public immutable MINT_PRICE = 0.01 ether;

  constructor(Alphabet _alphabet) {
    alphabet = _alphabet;
  }

  function mint(uint amount) public {
    uint value = MINT_PRICE * amount;
    _mint(amount, value);
  }

  function _mint(uint amount, uint value) internal {
    alphabet.mint{value: value}(amount);
  }

  function deposit() payable public returns (bool success) {
    return true;
  }
}

contract AlphabetTest is DSTest {
  Alphabet alphabet;
  User userA;
  User userB;
  Hevm hevm;
  ERC721Batcher batcher;

  function setUp() public {
    hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    alphabet = new Alphabet();
    batcher = new ERC721Batcher();
    userA = new User(alphabet);
    userB = new User(alphabet);

    uint eth = 100 ether;
    userA.deposit{value: eth}();
    userB.deposit{value: eth}();
  }

  function testMintOneGetBatch() public {
    userA.mint(5);
    userB.mint(2);
    uint256[] memory owned = batcher.getIds(address(alphabet), address(userB));
    assertEq(owned.length, 2);
    assertEq(owned[0], 5);
    assertEq(owned[1], 6);
  }
}
