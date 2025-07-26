// === QJuryReward.sol ===
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./QJuryRegistry.sol";

/// @title QJury Reward Contract
/// @notice Manages juror rewards and penalties after dispute resolution
/// @dev Interacts with JuryRegistry to slash or refund stakes

contract QJuryReward {
    QJuryRegistry public registry;

    constructor(address _registry) {
        registry = QJuryRegistry(_registry);
    }

    function reward(address juror) external {
        registry.rewardJuror(juror, 0.05 ether);
    }

    function slash(address juror) external {
        registry.slashJuror(juror);
    }
}
