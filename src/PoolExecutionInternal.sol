// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.20;

import { EnumerableSet } from '@solidstate-solidity/data/EnumerableSet.sol';
import { IERC721 } from '@solidstate-solidity/interfaces/IERC721.sol';
import { ERC1155BaseInternal } from '@solidstate-solidity/token/ERC1155/base/ERC1155BaseInternal.sol';
import { ERC20BaseInternal } from '@solidstate-solidity/token/ERC20/base/ERC20BaseInternal.sol';

import { PoolStorage as s } from './PoolStorage.sol';
import { Errors } from './Errors.sol';

/**
 * @notice Insrt Finance internal execution logic for asset exchanges
 */
abstract contract PoolExecutionInternal is ERC1155BaseInternal, ERC20BaseInternal {
    using EnumerableSet for EnumerableSet.AddressSet;

    function _swapNFTForShards(address collection, uint256 tokenId, uint16 keptShards, uint256 lpAmount) internal {
        _enforceCollectionWhitelist(collection);
        _enforceCollectionShardLimit(collection, keptShards);

        s.Layout storage l = s.layout();

        IERC721(collection).transferFrom(msg.sender, address(this), tokenId);
         
        l.unclaimedShards[collection] += l.collectionShardId[collection] - keptShards;
        
        _mint(msg.sender, l.collectionShardId[collection], keptShards, '0x');
        
        if (lpAmount > 0) {
            _mint(msg.sender, lpAmount);
        }       
    }

    function _enforceCollectionWhitelist(address collection) internal view {
        if(!s.layout().whitelistedCollections.contains(collection)) {
            revert Errors.INLP__OnlyWhitelistedCollections();
        }
    }

    function _enforceCollectionShardLimit(address collection, uint256 amount) internal view {
        if(s.layout().tokenShards[collection] < amount) {
            revert Errors.INLP__ShardsPerTokenExceeded();
        }
    }
}