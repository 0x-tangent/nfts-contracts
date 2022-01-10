// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.6;

// import "./ERC721.sol";

interface IERC721 {
  function balanceOf(address user) external returns (uint);
  function tokenURI(uint256 id) external returns (string memory);
}
interface IERC721Enumerable is IERC721 {
  function tokenOfOwnerByIndex(address user, uint256 i) external returns (uint256);
}
contract ERC721Batcher {

  // function getURIs(address erc721Address, address user) checkGas("getURIs") public returns(string[] memory) {
  function getURIs(address erc721Address, address user) public returns(string[] memory) {
    IERC721Enumerable nft = IERC721Enumerable(erc721Address);
    uint256 numTokens = nft.balanceOf(user);
    string[] memory uriList = new string[](numTokens);
    for (uint256 i; i < numTokens; i++) {
      uriList[i] = nft.tokenURI(nft.tokenOfOwnerByIndex(user, i));
    }
    return(uriList);
  }

  // function getIds(address erc721Address, address user) public checkGas("getIds") returns(uint256[] memory) {
  function getIds(address erc721Address, address user) public returns(uint256[] memory) {
  uint256 g1 = gasleft();
    IERC721Enumerable nft = IERC721Enumerable(erc721Address);
    uint256 numTokens = nft.balanceOf(user);
    uint256[] memory uriList = new uint256[](numTokens);
    for (uint256 i; i < numTokens; i++) {
      uriList[i] = nft.tokenOfOwnerByIndex(user, i);
    }

    uint256 g2 = gasleft();
    emit GasUsed(g1 - g2, "get.ids");
    return(uriList);
  }

  event GasUsed(uint,string);
  modifier checkGas(string memory gEvent) {
    uint g1 = gasleft();
    _;
    uint g2 = gasleft();
    emit GasUsed(g2 - g1, gEvent);
  }

}
