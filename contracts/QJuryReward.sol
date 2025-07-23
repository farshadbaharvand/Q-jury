// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

///********************************
/// @title QJury Reward Contract
/// @notice Manages juror rewards and penalties after dispute resolution
/// @dev Interacts with JuryRegistry to slash or refund stakes
///********************************

interface IJuryRegistry {
    function rewardJuror(address juror) external;
    function slashJuror(address juror) external;
}

contract QJuryReward {
    address public admin;
    IJuryRegistry public juryRegistry;

    event RewardIssued(address indexed juror);
    event PenaltyIssued(address indexed juror);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin allowed");
        _;
    }

    constructor(address _juryRegistry) {
        admin = msg.sender;
        juryRegistry = IJuryRegistry(_juryRegistry);
    }

    /// @notice Reward a juror by refunding their stake
    function reward(address juror) external onlyAdmin {
        juryRegistry.rewardJuror(juror);
        emit RewardIssued(juror);
    }

    /// @notice Penalize a juror by slashing their stake
    function penalize(address juror) external onlyAdmin {
        juryRegistry.slashJuror(juror);
        emit PenaltyIssued(juror);
    }
}
