// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.20;

import { IERC165 } from "@solidstate/contracts/interfaces/IERC165.sol";
import { IERC721 } from "@solidstate/contracts/interfaces/IERC721.sol";
import { ERC721MetadataStorage } from "@solidstate/contracts/token/ERC721/metadata/ERC721MetadataStorage.sol";
import { SolidStateERC721 } from "@solidstate/contracts/token/ERC721/SolidStateERC721.sol";

contract ERC721CollectionMock is SolidStateERC721 {
    uint256 public id;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI
    ) {
        ERC721MetadataStorage.Layout storage l = ERC721MetadataStorage.layout();
        l.name = name;
        l.symbol = symbol;
        l.baseURI = baseURI;

        _setSupportsInterface(type(IERC165).interfaceId, true);
        _setSupportsInterface(type(IERC721).interfaceId, true);
    }

    function mint(address to, uint256 amount) external {
        for (uint256 i; i < amount; ++i) {
            _mint(to, id);
            ++id;
        }
    }
}
