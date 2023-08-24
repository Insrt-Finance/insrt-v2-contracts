// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.21;

import "forge-std/StdStorage.sol";
import "forge-std/Test.sol";
import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";
import { AssetType } from "../../../../contracts/enums/AssetType.sol";
import { PerpetualMintStorage as Storage } from "../../../../contracts/facets/L2/PerpetualMint/Storage.sol";

/// @title StorageRead library
/// @dev read values from PerpetualMintStorage directly
abstract contract StorageRead is Test {
    using stdStorage for StdStorage;

    /// @dev read vrfConfig value directly from storage
    /// @param target address of contract to read storage from
    /// @return config vrfConfig value
    function _vrfConfig(
        address target
    ) internal view returns (Storage.VRFConfig memory config) {
        bytes32 slot = Storage.STORAGE_SLOT; //VRFConfig storage slot

        bytes32 secondSlot = bytes32(uint256(slot) + 1); // second slot of VRFConfig struct

        bytes32 remainingConfig = vm.load(target, secondSlot);

        config.keyHash = vm.load(target, slot);
        config.subscriptionId = uint64(uint256(remainingConfig));
        config.callbackGasLimit = uint32(uint256(remainingConfig) >> 64);
        config.minConfirmations = uint16(uint256(remainingConfig) >> 96);
    }

    /// @dev read protocolFees value directly from storage
    /// @param target address of contract to read storage from
    /// @return fees protocolFees value
    function _protocolFees(
        address target
    ) internal view returns (uint256 fees) {
        bytes32 slot = bytes32(
            uint256(Storage.STORAGE_SLOT) + 2 // protocolFees storage slot
        );

        fees = uint256(vm.load(target, slot));
    }

    /// @dev read mintFeeBP value directly from storage
    /// @param target address of contract to read storage from
    /// @return feeBP mintFeeBP value
    function _mintFeeBP(address target) internal view returns (uint32 feeBP) {
        bytes32 slot = bytes32(
            uint256(Storage.STORAGE_SLOT) + 3 // mintFeeBP storage slot
        );

        feeBP = uint32(uint256(vm.load(target, slot)) >> 64); // Shift right by 64 bits to move mintFeeBP into the lower-order bytes
    }

    /// @dev read activeCollections values from activeCollections EnumerableSet.AddressSet
    /// @param target address of contract to read storage from
    /// @return collections array of collection address values from EnumerableSet.AddressSet._inner._values
    function _activeCollections(
        address target
    ) internal view returns (address[] memory collections) {
        bytes32 enumerableSetSlot = bytes32(uint256(Storage.STORAGE_SLOT) + 4); // activeCollections storage slot;

        uint256 length = uint256(vm.load(target, enumerableSetSlot)); // read length of array

        bytes32 valueSlot = keccak256(abi.encodePacked(enumerableSetSlot)); // grab storage slot of enumerableSet._inner._values

        address[] memory tempCollections = new address[](length);

        for (uint256 i; i < length; ++i) {
            tempCollections[i] = address(
                uint160(
                    uint256(vm.load(target, bytes32(uint256(valueSlot) + i)))
                )
            );
        }

        collections = tempCollections;
    }

    /// @dev read requestMint value directly from storage
    /// @param target address of contract to read storage from
    /// @param requestId id of Chainlink VRF request
    /// @return minter minter address value
    function _requestMinter(
        address target,
        uint256 requestId
    ) internal view returns (address minter) {
        bytes32 slot = keccak256(
            abi.encode(
                requestId, // id of Chainlink VRF request
                uint256(Storage.STORAGE_SLOT) + 6 // requestMinter mapping storage slot
            )
        );

        minter = address(uint160(uint256(vm.load(target, slot))));
    }

    /// @dev read requestCollection value directly from storage
    /// @param target address of contract to read storage from
    /// @param requestId id of Chainlink VRF request
    /// @return collection collecftion address value
    function _requestCollection(
        address target,
        uint256 requestId
    ) internal view returns (address collection) {
        bytes32 slot = keccak256(
            abi.encode(
                requestId, // id of Chainlink VRF request
                uint256(Storage.STORAGE_SLOT) + 7 // requestCollection mapping storage slot
            )
        );

        collection = address(uint160(uint256(vm.load(target, slot))));
    }

    /// @dev read collectionType value directly from storage
    /// @param target address of contract to read storage from
    /// @param collection address of collection
    /// @return assetType type of collection
    function _collectionType(
        address target,
        address collection
    ) internal view returns (AssetType assetType) {
        bytes32 slot = keccak256(
            abi.encode(
                collection, // address of collection
                uint256(Storage.STORAGE_SLOT) + 8 // collectionType mapping storage slot
            )
        );

        assetType = vm.load(target, slot) == 0
            ? AssetType.ERC1155
            : AssetType.ERC721;
    }

    /// @dev read collectionEarnings value directly from storage
    /// @param target address of contract to read storage from
    /// @param collection address of collection
    /// @return earnings earnings of collection value
    function _collectionEarnings(
        address target,
        address collection
    ) internal view returns (uint256 earnings) {
        bytes32 slot = keccak256(
            abi.encode(
                collection, // address of collection
                uint256(Storage.STORAGE_SLOT) + 9 // collectionEarnings mapping storage slot
            )
        );

        earnings = uint256(vm.load(target, slot));
    }

    /// @dev read lastCollectionEarnings value directly from storage
    /// @param target address of contract to read storage from
    /// @param collection address of collection
    /// @return earnings earnings of collection value
    function _lastCollectionEarnings(
        address target,
        address collection
    ) internal view returns (uint256 earnings) {
        bytes32 slot = keccak256(
            abi.encode(
                collection, // address of collection
                uint256(Storage.STORAGE_SLOT) + 10 // lastCollectionEarnings mapping storage slot
            )
        );

        earnings = uint256(vm.load(target, slot));
    }

    /// @dev read baseMultiplier value directly from storage
    /// @param target address of contract to read storage from
    /// @param collection address of collection
    /// @return multiplier baseMultiplier value of collection
    function _baseMultiplier(
        address target,
        address collection
    ) internal view returns (uint256 multiplier) {
        bytes32 slot = keccak256(
            abi.encode(
                collection, // address of collection
                uint256(Storage.STORAGE_SLOT) + 11 // baseMultiplier mapping storage slot
            )
        );

        multiplier = uint256(vm.load(target, slot));
    }

    /// @dev read collectionMintPrice value directly from storage
    /// @param target address of contract to read storage from
    /// @param collection address of collection
    /// @return mintPrice price of mint value
    function _collectionMintPrice(
        address target,
        address collection
    ) internal view returns (uint256 mintPrice) {
        bytes32 slot = keccak256(
            abi.encode(
                collection, // address of collection
                uint256(Storage.STORAGE_SLOT) + 12 // collectionMintPrice mapping storage slot
            )
        );

        mintPrice = uint256(vm.load(target, slot));
    }

    /// @dev read totalRisk value directly from storage
    /// @param target address of contract to read storage from
    /// @param collection address of collection
    /// @return risk totalRisk of collection value
    function _totalRisk(
        address target,
        address collection
    ) internal view returns (uint256 risk) {
        bytes32 slot = keccak256(
            abi.encode(
                collection, // address of collection
                uint256(Storage.STORAGE_SLOT) + 13 // totalRisk mapping storage slot
            )
        );

        risk = uint256(vm.load(target, slot));
    }

    /// @dev read totalActiveTokens value directly from storage
    /// @param target address of contract to read storage from
    /// @param collection address of collection
    /// @return amount active token amount value
    function _totalActiveTokens(
        address target,
        address collection
    ) internal view returns (uint256 amount) {
        bytes32 slot = keccak256(
            abi.encode(
                collection, // address of collection
                uint256(Storage.STORAGE_SLOT) + 14 // totalActiveTokens mapping storage slot
            )
        );

        amount = uint256(vm.load(target, slot));
    }

    /// @dev read activeTokenIds values from activeTokenIds EnumerableSet.UintSet
    /// @param target address of contract to read storage from
    /// @param collection address of collection
    /// @return tokenIds array of tokenIds values from EnumerableSet.UintSet._inner._values
    function _activeTokenIds(
        address target,
        address collection
    ) internal view returns (uint256[] memory tokenIds) {
        bytes32 enumerableSetSlot = keccak256(
            abi.encode(
                collection, // address of collection
                uint256(Storage.STORAGE_SLOT) + 15 // activeTokenIds mapping storage slot
            )
        );

        uint256 length = uint256(vm.load(target, enumerableSetSlot)); // read length of array

        bytes32 valueSlot = keccak256(abi.encodePacked(enumerableSetSlot)); // grab storage slot of enumerableSet._inner._values

        uint256[] memory tempTokenIds = new uint256[](length);

        for (uint256 i; i < length; ++i) {
            tempTokenIds[i] = uint256(
                vm.load(target, bytes32(uint256(valueSlot) + i))
            );
        }

        tokenIds = tempTokenIds;
    }

    /// @dev read tokenRisk value directly from storage
    /// @param target address of contract to read storage from
    /// @param collection address of collection
    /// @param tokenId id of token
    /// @return risk total token risk value
    function _tokenRisk(
        address target,
        address collection,
        uint256 tokenId
    ) internal view returns (uint256 risk) {
        bytes32 slot = keccak256(
            abi.encode(
                tokenId, // id of token
                keccak256(
                    abi.encode(
                        collection, // address of collection
                        uint256(Storage.STORAGE_SLOT) + 16 // tokenRisk mapping storage slot
                    )
                )
            )
        );

        risk = uint256(vm.load(target, slot));
    }

    /// @dev read escrowedERC721Owner value directly from storage
    /// @param target address of contract to read storage from
    /// @param collection address of collection
    /// @param tokenId id of token
    /// @return owner address of owner value
    function _escrowedERC721Owner(
        address target,
        address collection,
        uint256 tokenId
    ) internal view returns (address owner) {
        bytes32 slot = keccak256(
            abi.encode(
                tokenId, // the ERC721 token id
                keccak256(
                    abi.encode(
                        collection, // the ERC721 collection
                        uint256(Storage.STORAGE_SLOT) + 17 // escrowedERC721Owner mapping slot
                    )
                )
            )
        );

        owner = address(uint160(uint256(vm.load(target, slot))));
    }

    /// @dev read owner values from activeERC1155TokenOwners EnumerableSet.AddressSet
    /// @param target address of contract to read storage from
    /// @param collection address of collection
    /// @param tokenId id of token
    /// @return owners array of owner address values from EnumerableSet.AddressSet._inner._values
    function _activeERC1155Owners(
        address target,
        address collection,
        uint256 tokenId
    ) internal view returns (address[] memory owners) {
        bytes32 enumerableSetSlot = keccak256(
            abi.encode(
                tokenId, // the ERC1155 token id
                keccak256(
                    abi.encode(
                        collection, // the ERC1155 collection
                        uint256(Storage.STORAGE_SLOT) + 18 // activeERC1155TokenOwners mapping slot
                    )
                )
            )
        );

        uint256 length = uint256(vm.load(target, enumerableSetSlot)); // read length of array

        bytes32 valueSlot = keccak256(abi.encodePacked(enumerableSetSlot)); // grab storage slot of enumerableSet._inner._values

        address[] memory tempOwners = new address[](length);

        for (uint256 i; i < length; ++i) {
            tempOwners[i] = address(
                uint160(
                    uint256(vm.load(target, bytes32(uint256(valueSlot) + i)))
                )
            );
        }

        owners = tempOwners;
    }

    /// @dev read multiplierOffset value directly from storage
    /// @param target address of contract to read storage from
    /// @param depositor address of depositor
    /// @param collection address of collection
    /// @return offset depositor multiplierOffset value
    function _multiplierOffset(
        address target,
        address depositor,
        address collection
    ) internal view returns (uint256 offset) {
        bytes32 slot = keccak256(
            abi.encode(
                collection, // address of collection
                keccak256(
                    abi.encode(
                        depositor, // address of depositor
                        uint256(Storage.STORAGE_SLOT) + 19 // multiplierOffset mapping storage slot
                    )
                )
            )
        );

        offset = uint256(vm.load(target, slot));
    }

    /// @dev read depositorEarnings value directly from storage
    /// @param target address of contract to read storage from
    /// @param depositor address of depositor
    /// @param collection address of collection
    /// @return earnings depositor earnings value
    function _depositorEarnings(
        address target,
        address depositor,
        address collection
    ) internal view returns (uint256 earnings) {
        bytes32 slot = keccak256(
            abi.encode(
                collection, // address of collection
                keccak256(
                    abi.encode(
                        depositor, // address of depositor
                        uint256(Storage.STORAGE_SLOT) + 20 // depositorEarnings mapping storage slot
                    )
                )
            )
        );

        earnings = uint256(vm.load(target, slot));
    }

    /// @dev read activeTokens value directly from storage
    /// @param target address of contract to read storage from
    /// @param depositor address of depositor
    /// @param collection address of collection
    /// @return amount active tokens amount value
    function _activeTokens(
        address target,
        address depositor,
        address collection
    ) internal view returns (uint256 amount) {
        bytes32 slot = keccak256(
            abi.encode(
                collection, // address of collection
                keccak256(
                    abi.encode(
                        depositor, // address of depositor
                        uint256(Storage.STORAGE_SLOT) + 21 // activeTokens mapping storage slot
                    )
                )
            )
        );

        amount = uint256(vm.load(target, slot));
    }

    /// @dev read inactiveTokens value directly from storage
    /// @param target address of contract to read storage from
    /// @param depositor address of depositor
    /// @param collection address of collection
    /// @return amount inactive tokens amount value
    function _inactiveTokens(
        address target,
        address depositor,
        address collection
    ) internal view returns (uint256 amount) {
        bytes32 slot = keccak256(
            abi.encode(
                collection, // address of collection
                keccak256(
                    abi.encode(
                        depositor, // address of depositor
                        uint256(Storage.STORAGE_SLOT) + 22 // inactiveTokens mapping storage slot
                    )
                )
            )
        );

        amount = uint256(vm.load(target, slot));
    }

    /// @dev read totalDepositorRisk value directly from storage
    /// @param target address of contract to read storage from
    /// @param depositor address of depositor
    /// @param collection address of collection
    /// @return risk total depositor risk value
    function _totalDepositorRisk(
        address target,
        address depositor,
        address collection
    ) internal view returns (uint256 risk) {
        bytes32 slot = keccak256(
            abi.encode(
                collection, // address of collection
                keccak256(
                    abi.encode(
                        depositor, // address of depositor
                        uint256(Storage.STORAGE_SLOT) + 23 // totalDepositorRisk mapping storage slot
                    )
                )
            )
        );

        risk = uint256(vm.load(target, slot));
    }

    /// @dev read depositor token Risk value directly from storage
    /// @param target address of contract to read storage from
    /// @param depositor address of depositor
    /// @param collection address of collection
    /// @param tokenId id of token
    /// @return risk depositor token risk value
    function _depositorTokenRisk(
        address target,
        address depositor,
        address collection,
        uint256 tokenId
    ) internal view returns (uint256 risk) {
        bytes32 slot = keccak256(
            abi.encode(
                tokenId, //id of token
                keccak256(
                    abi.encode(
                        collection, //address of collection
                        keccak256(
                            abi.encode(
                                depositor, // address of depositor
                                uint256(Storage.STORAGE_SLOT) + 24 // depositorTokenRisk mapping storage slot
                            )
                        )
                    )
                )
            )
        );

        risk = uint256(vm.load(target, slot));
    }

    /// @dev read activeERC1155Tokens value directly from storage
    /// @param target address of contract to read storage from
    /// @param depositor address of depositor
    /// @param collection address of collection
    /// @param tokenId id of token
    /// @return amount active ERC1155 tokens amount
    function _activeERC1155Tokens(
        address target,
        address depositor,
        address collection,
        uint256 tokenId
    ) internal view returns (uint256 amount) {
        bytes32 slot = keccak256(
            abi.encode(
                tokenId, // id of token
                keccak256(
                    abi.encode(
                        collection, // address of collection
                        keccak256(
                            abi.encode(
                                depositor, // address of depositor
                                uint256(Storage.STORAGE_SLOT) + 25 // activeERC1155Tokens mapping storage slot
                            )
                        )
                    )
                )
            )
        );

        amount = uint256(vm.load(target, slot));
    }

    /// @dev read inactiveERC1155Tokens value directly from storage
    /// @param target address of contract to read storage from
    /// @param depositor address of depositor
    /// @param collection address of collection
    /// @param tokenId id of token
    /// @return amount inactive ERC1155 tokens amount
    function _inactiveERC1155Tokens(
        address target,
        address depositor,
        address collection,
        uint256 tokenId
    ) internal view returns (uint256 amount) {
        bytes32 slot = keccak256(
            abi.encode(
                tokenId, // id of token
                keccak256(
                    abi.encode(
                        collection, // address of collection
                        keccak256(
                            abi.encode(
                                depositor, // address of depositor
                                uint256(Storage.STORAGE_SLOT) + 26 // inactiveERC1155Tokens mapping storage slot
                            )
                        )
                    )
                )
            )
        );

        amount = uint256(vm.load(target, slot));
    }

    /// @dev read maxActiveTokens value directly from storage
    /// @param target address of contract to read storage from
    /// @return maxActiveTokens maxActiveTokens value
    function _maxActiveTokens(
        address target
    ) internal view returns (uint256 maxActiveTokens) {
        bytes32 slot = bytes32(uint256(Storage.STORAGE_SLOT) + 27);

        maxActiveTokens = uint256(vm.load(target, slot));
    }
}
