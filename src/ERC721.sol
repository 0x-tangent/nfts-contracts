// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author tangent, adapted from Solmate at (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
  /*///////////////////////////////////////////////////////////////
    EVENTS
  //////////////////////////////////////////////////////////////*/

  event Transfer(address indexed from, address indexed to, uint256 indexed id);

  event Approval(address indexed owner, address indexed spender, uint256 indexed id);

  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  /*///////////////////////////////////////////////////////////////
    METADATA STORAGE/LOGIC
  //////////////////////////////////////////////////////////////*/

  string public name;

  string public symbol;

  function tokenURI(uint256 id) public view virtual returns (string memory);

  /*///////////////////////////////////////////////////////////////
    ERC721 STORAGE                        
  //////////////////////////////////////////////////////////////*/

  /** @dev to avoid storing redundant data in both `owners` and `balances`
  **      use an ordered, sequential array so that `index == tokenId`
  **      this causes `balanceOf` to look a little ugly, but otherwise
  **      reduces gas for minting and token transfers
 */
  address[] public owners;

  /** @dev since we aren't explicitly tracking balances with a `mapping(address => uint)`
  **      as is normally done, `balanceOf` has to loop through the full array to
  **      count the user balance. the for loop doesn't add to minting or transfer costs.
  **      (would only affect gas if another contract relies on balanceOf, in which case,
  **       it is significantly worse.)
  **       inspired by this article: https://medium.com/@nftchance/the-cannibalization-of-nfts-by-openzeppelin-by-insanely-high-gas-prices-cd2c9a7c1e7
 */
  function balanceOf(address user) public view returns (uint) {
    uint balance = 0;
    for(uint256 i = 0; i < owners.length; i++) {
      if(owners[i] == user) {
        balance++;
      }
    }

    return balance;
  }

  function ownerOf(uint256 id) public view returns (address) {
    require(id < owners.length, "ID EXCEEDS MAX SUPPLY");
    address owner = owners[id];
    require(owner != address(0), "TOKEN DOESN'T EXIST");
    return owner;
  }

  mapping(uint256 => address) public getApproved;

  mapping(address => mapping(address => bool)) public isApprovedForAll;

  /*///////////////////////////////////////////////////////////////
    ERC721Enumerable Extensions
  //////////////////////////////////////////////////////////////*/

  function totalSupply() public view returns (uint) {
    uint256 burnedTokens = 0;
    for(uint i = 0; i < owners.length; i++) {
      if(owners[i] == address(0)) {
        burnedTokens++;
      }
    }
    return owners.length - burnedTokens;
  }

  function tokensOfOwner(address user) public view returns (uint256[] memory) {
    uint256 userBalance = balanceOf(user);
    uint256[] memory owned = new uint256[](userBalance);
    uint256 found = 0;
    for(uint256 i = 0; i < totalSupply(); i++) {
      if(owners[i] == user) {
        owned[found++] = i;
      }
    }

    return owned;
  }

  function tokenOfOwnerByIndex(address user, uint256 id) public view returns (uint256) {
    return tokensOfOwner(user)[id];
  }

  function tokenByIndex(uint256 id) public pure returns (uint256) {
    return id;
  }

  /*///////////////////////////////////////////////////////////////
  CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

  constructor(string memory _name, string memory _symbol) {
    name = _name;
    symbol = _symbol;
  }

  /*///////////////////////////////////////////////////////////////
  ERC721 LOGIC
  //////////////////////////////////////////////////////////////*/

  function approve(address spender, uint256 id) public virtual {
    address owner = owners[id];

    require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

    getApproved[id] = spender;

    emit Approval(owner, spender, id);
  }

  function setApprovalForAll(address operator, bool approved) public virtual {
    isApprovedForAll[msg.sender][operator] = approved;

    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function transferFrom(
    address from,
    address to,
    uint256 id
  ) public virtual {
    require(from == owners[id], "WRONG_FROM");

    require(to != address(0), "INVALID_RECIPIENT");

    require(
      msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
      "NOT_AUTHORIZED"
    );

    owners[id] = to;

    delete getApproved[id];

    emit Transfer(from, to, id);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id
  ) public virtual {
    transferFrom(from, to, id);

    require(
      to.code.length == 0 ||
      ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
      ERC721TokenReceiver.onERC721Received.selector,
      "UNSAFE_RECIPIENT"
    );
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    bytes memory data
  ) public virtual {
    transferFrom(from, to, id);

    require(
      to.code.length == 0 ||
      ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
      ERC721TokenReceiver.onERC721Received.selector,
      "UNSAFE_RECIPIENT"
    );
  }

  /*///////////////////////////////////////////////////////////////
  ERC165 LOGIC
  //////////////////////////////////////////////////////////////*/

  function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
    return
    interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
      interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
      interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
  }

  /*///////////////////////////////////////////////////////////////
  INTERNAL MINT/BURN LOGIC
  //////////////////////////////////////////////////////////////*/

  function _mint(address to, uint256 id) internal virtual {
    require(to != address(0), "INVALID_RECIPIENT");
    require(owners.length < (id + 1), "ALREADY_MINTED");
    owners.push(to);

    emit Transfer(address(0), to, id);
  }

  function _burn(uint256 id) internal virtual {
    address owner = owners[id];

    require(owners[id] != address(0), "NON_EXISTENT_TOKEN");

    owners[id] = address(0);

    delete getApproved[id];

    emit Transfer(owner, address(0), id);
  }

  /*///////////////////////////////////////////////////////////////
  INTERNAL SAFE MINT LOGIC
  //////////////////////////////////////////////////////////////*/

  function _safeMint(address to, uint256 id) internal virtual {
    _mint(to, id);

    require(
      to.code.length == 0 ||
      ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
      ERC721TokenReceiver.onERC721Received.selector,
      "UNSAFE_RECIPIENT"
    );
  }

  function _safeMint(
    address to,
    uint256 id,
    bytes memory data
  ) internal virtual {
    _mint(to, id);

    require(
      to.code.length == 0 ||
      ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
      ERC721TokenReceiver.onERC721Received.selector,
      "UNSAFE_RECIPIENT"
    );
  }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
  function onERC721Received(
    address operator,
    address from,
    uint256 id,
    bytes calldata data
  ) external returns (bytes4);
}
