// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { IERC165 } from "@solidstate/contracts/interfaces/IERC165.sol";
import { SolidStateERC1155 } from "@solidstate/contracts/token/ERC1155/SolidStateERC1155.sol";

contract ERC1155CollectionMock is SolidStateERC1155 {
    constructor() {
        _setSupportsInterface(type(IERC165).interfaceId, true);
        _setSupportsInterface(type(IERC1155).interfaceId, true);
    }

    function mint(address account, uint256 id, uint256 amount) external {
        _mint(account, id, amount, "0x");
    }
}
