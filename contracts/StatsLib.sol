// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

library StatsLib {
    struct CollectionStats {
        uint256 volume24h;
        uint256 volume7d;
        uint256 sales24h;
        uint256 sales7d;
        uint256 lastUpdateTime24h;
        uint256 lastUpdateTime7d;
    }

    function updateStats(
        CollectionStats storage stats,
        uint256 price,
        uint256 currentTime
    ) external {
        if (currentTime - stats.lastUpdateTime24h <= 1 days) {
            stats.volume24h += price;
            stats.sales24h++;
        } else {
            stats.volume24h = price;
            stats.sales24h = 1;
            stats.lastUpdateTime24h = currentTime;
        }

        if (currentTime - stats.lastUpdateTime7d <= 7 days) {
            stats.volume7d += price;
            stats.sales7d++;
        } else {
            stats.volume7d = price;
            stats.sales7d = 1;
            stats.lastUpdateTime7d = currentTime;
        }
    }
}