// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "ds-test/test.sol";

import "../Alphabet.sol";

abstract contract Hevm {
  function warp(uint) public virtual;
}

contract User {
  Alphabet alphabet;

  uint public immutable MINT_PRICE = 0.001 ether;

  constructor(Alphabet _alphabet) {
    alphabet = _alphabet;
  }

  function mint(uint amount) public {
    uint value = MINT_PRICE * amount;
    _mint(amount, value);
  }

  function badMint(uint amount) public {
    uint value = 1 * amount;
    _mint(amount, value);
  }

  function _mint(uint amount, uint value) internal {
    alphabet.mint{value: value}(amount);
  }

  function burn(uint id) public {
    alphabet.burn(id);
  }

  function transferFrom(address from, address to, uint256 id) public {
    alphabet.transferFrom(from, to, id);
  }

  function approve(address operator, uint256 id) public {
    alphabet.approve(operator, id);
  }
  function approveAll(address operator, bool isApproved) public {
    alphabet.setApprovalForAll(operator, isApproved);
  }

  function deposit() payable public returns (bool success) {
    return true;
  }
}

contract AlphabetTest is DSTest {
  Alphabet alphabet;
  User userA;
  User userB;
  User userC;
  User userNoFunds;
  Hevm hevm;

  function setUp() public {
    hevm = Hevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);
    alphabet = new Alphabet();
    userA = new User(alphabet);
    userB = new User(alphabet);
    userC = new User(alphabet);
    userNoFunds = new User(alphabet);

    uint eth = 100 ether;
    userA.deposit{value: eth}();
    userB.deposit{value: eth}();
    userC.deposit{value: eth}();
  }

  //   function testMintOnlyOne() public {
  //     userA.mint(1);
  //     uint balance = alphabet.balanceOf(address(userA));
  //     assertEq(balance, 1);
  //   }
  // 
  //   function testMintOneOrFive() public {
  //     userA.mint(5);
  //     uint balance = alphabet.balanceOf(address(userA));
  //     assertEq(balance, 5);
  //   }

  function testMintOne() public {
    userA.mint(1);
    uint balance = alphabet.balanceOf(address(userA));
    assertEq(1, balance);
  }
  function testMintOneOrFive() public {
    userA.mint(5);
    uint balance = alphabet.balanceOf(address(userA));
    assertEq(5, balance);
  }

  function testBurnAdjustsUserBalance() public {
    userA.mint(5);

    uint balance1 = alphabet.balanceOf(address(userA));
    assertEq(balance1, 5);
    userA.burn(2);

    uint balance2 = alphabet.balanceOf(address(userA));
    assertEq(balance2, 4);
  }

  function testBurnAdjustsTotalSupply() public {
    userA.mint(100);
    uint postMintSupply = alphabet.totalSupply();
    assertEq(postMintSupply, 100);

    userA.burn(0);
    userA.burn(1);
    userA.burn(2);
    userA.burn(3);
    userA.burn(4);

    uint postBurnSupply = alphabet.totalSupply();
    assertEq(postBurnSupply, 95);
  }

//   function testBurnedTokensAreZeroWithNoBurns() public {
//     assertEq(alphabet.burnedTokens(), 0);
//     userA.mint(5);
//     assertEq(alphabet.burnedTokens(), 0);
//     userA.burn(1);
//     assertEq(alphabet.burnedTokens(), 1);
//     userA.burn(3);
//     userA.burn(4);
//     assertEq(alphabet.burnedTokens(), 3);
//   }

  function testFailBurnWithZeroOwned() public {
    userA.burn(0);
  }
  function testFailBurnWithUnownedToken() public {
    userA.mint(1);
    userA.burn(50);
  }

  function testFailMintWrongAmount() public {
    userA.badMint(1);
  }
  function testFailMintNotEnoughFunds() public {
    userNoFunds.mint(1);
  }

  function testTransferToUserB() public {
    userA.mint(1);
    assertEq(alphabet.balanceOf(address(userA)), 1);
    assertEq(alphabet.balanceOf(address(userB)), 0);
    userA.transferFrom(address(userA), address(userB), 0);
    assertEq(alphabet.balanceOf(address(userA)), 0);
    assertEq(alphabet.balanceOf(address(userB)), 1);
  }

  function testFailTransferWithoutApproval() public {
    userA.mint(1);
    userB.transferFrom(address(userA), address(userC), 0);
  }

  function testTransferForWithApprove1() public {
    userA.mint(1);
    userA.approve(address(userB), 0);
    userB.transferFrom(address(userA), address(userC), 0);
    assertEq(alphabet.balanceOf(address(userA)), 0);
    assertEq(alphabet.balanceOf(address(userC)), 1);
  }
  function testFailApproveForUnownedToken() public {
    userA.mint(1);
    userB.approve(address(userA), 0);
  }
  function testFailApproveForNonexistentToken() public {
    userA.mint(1);
    userA.approve(address(userA), 1);
  }
  function testTransferForWithApproveAll() public {
    userA.mint(1);
    userA.approveAll(address(userB), true);
    userB.transferFrom(address(userA), address(userC), 0);
  }
  function testFailTransferForWithRevokedApproval() public {
    userA.mint(3);
    userA.approveAll(address(userB), true);
    userB.transferFrom(address(userA), address(userC), 0);
    userA.approveAll(address(userB), false);
    userB.transferFrom(address(userA), address(userC), 1);
  }
  function testFailTransferForUnownedTokens() public {
    userA.mint(3);
    userC.mint(3);
    userA.approveAll(address(userB), true);
    userB.transferFrom(address(userA), address(userC), 4);
  }

  function testTokenByIndex() public {
    userA.mint(5);
    uint tokenIndex = alphabet.tokenByIndex(3);
    assertEq(tokenIndex, 3);
  }
}
