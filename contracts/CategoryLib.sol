// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library CategoryLib {
    error InvalidCategory();
    error CategoryExists();
    error CategoryNotFound();

    struct CategoryStorage {
        mapping(string => bool) validCategories;
        mapping(string => address[]) categoryCollections;
        string[] categoryNames;
    }

    function addCategory(
        CategoryStorage storage self,
        string calldata category
    ) external {
        if (self.validCategories[category]) revert CategoryExists();
        self.validCategories[category] = true;
        self.categoryNames.push(category);
    }

    function removeCategory(
        CategoryStorage storage self,
        string calldata category
    ) external {
        if (!self.validCategories[category]) revert CategoryNotFound();
        self.validCategories[category] = false;

        for (uint i = 0; i < self.categoryNames.length; i++) {
            if (
                keccak256(bytes(self.categoryNames[i])) ==
                keccak256(bytes(category))
            ) {
                self.categoryNames[i] = self.categoryNames[
                    self.categoryNames.length - 1
                ];
                self.categoryNames.pop();
                break;
            }
        }
    }

    function addCollectionToCategory(
        CategoryStorage storage self,
        string calldata category,
        address collection
    ) external {
        if (!self.validCategories[category]) revert InvalidCategory();
        self.categoryCollections[category].push(collection);
    }

    function getValidCategories(
        CategoryStorage storage self
    ) external view returns (string[] memory) {
        uint256 validCount = 0;
        for (uint256 i = 0; i < self.categoryNames.length; i++) {
            if (self.validCategories[self.categoryNames[i]]) validCount++;
        }

        string[] memory result = new string[](validCount);
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < self.categoryNames.length; i++) {
            if (self.validCategories[self.categoryNames[i]]) {
                result[currentIndex] = self.categoryNames[i];
                currentIndex++;
            }
        }

        return result;
    }
}
