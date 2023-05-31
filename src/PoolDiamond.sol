// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import { ERC20MetadataInternal } from '@solidstate-solidity/token/ERC20/metadata/ERC20MetadataInternal.sol';
import { ERC1155MetadataInternal } from '@solidstate-solidity/token/ERC1155/metadata/ERC1155MetadataInternal.sol';
import { SolidStateDiamond } from '@solidstate-solidity/proxy/diamond/SolidStateDiamond.sol';

/**
 * @title Diamond proxy used as centrally controlled INLP implementation
 */
contract PoolDiamond is ERC20MetadataInternal, ERC1155MetadataInternal,  SolidStateDiamond {
    constructor(
        string memory shardBaseURI,
        string memory lpName,
        string memory lpSymbol
    ) {
        //ERC1155
        _setBaseURI(shardBaseURI);
        
        //ERC20
        _setName(lpName);
        _setSymbol(lpSymbol);
    }
}