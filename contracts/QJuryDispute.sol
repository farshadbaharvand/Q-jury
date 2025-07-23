// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

///********************************
/// @title QJuryDispute Contract
/// @notice Handles voting and resolution for disputes assigned to jurors
/// @dev Works with JuryRegistry contract for reward/slash logic
///********************************

interface IJuryRegistry {
    function rewardJuror(address juror) external;
    function slashJuror(address juror) external;
    function jurors(address juror) external view returns (uint256, bool, bool);
}

contract QJuryDispute {
    IJuryRegistry public juryRegistry;
    address public admin;
    uint256 public disputeCount;

    ///********************************
    /// @dev Represents a single dispute and its voting status
    ///********************************
    struct Dispute {
        address[] jurors;          // List of assigned jurors
        mapping(address => bool) hasVoted;
        mapping(address => bool) vote;   // true: support, false: against
        uint256 yesVotes;
        uint256 noVotes;
        bool resolved;
        uint256 deadline;
    }

    mapping(uint256 => Dispute) public disputes;

    event DisputeCreated(uint256 disputeId, address[] jurors, uint256 deadline);
    event Voted(address indexed juror, uint256 indexed disputeId, bool vote);
    event DisputeResolved(uint256 indexed disputeId, bool finalDecision);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }

    constructor(address _juryRegistry) {
        juryRegistry = IJuryRegistry(_juryRegistry);
        admin = msg.sender;
    }

    ///********************************
    /// @notice Create a new dispute and assign jurors
    /// @param _jurors List of juror addresses (must be registered/staked)
    /// @param _votingPeriod Voting period in seconds
    ///********************************
    function createDispute(address[] memory _jurors, uint256 _votingPeriod) external onlyAdmin {
        disputeCount += 1;
        Dispute storage d = disputes[disputeCount];
        d.jurors = _jurors;
        d.deadline = block.timestamp + _votingPeriod;

        emit DisputeCreated(disputeCount, _jurors, d.deadline);
    }

    ///********************************
    /// @notice Jurors cast their vote
    /// @param disputeId The ID of the dispute
    /// @param _vote true = yes, false = no
    ///********************************
    function voteOnDispute(uint256 disputeId, bool _vote) external {
        Dispute storage d = disputes[disputeId];
        require(block.timestamp <= d.deadline, "Voting period ended");
        require(!d.resolved, "Dispute already resolved");
        require(isJurorAssigned(disputeId, msg.sender), "Not assigned juror");
        require(!d.hasVoted[msg.sender], "Already voted");

        d.hasVoted[msg.sender] = true;
        d.vote[msg.sender] = _vote;

        if (_vote) {
            d.yesVotes += 1;
        } else {
            d.noVotes += 1;
        }

        emit Voted(msg.sender, disputeId, _vote);
    }

    ///********************************
    /// @notice Resolve a dispute and reward/slash jurors based on majority
    /// @dev Can only be called by admin after deadline
    ///********************************
    function resolveDispute(uint256 disputeId) external onlyAdmin {
        Dispute storage d = disputes[disputeId];
        require(block.timestamp > d.deadline, "Voting still active");
        require(!d.resolved, "Already resolved");

        bool finalDecision = d.yesVotes >= d.noVotes;
        d.resolved = true;

        for (uint256 i = 0; i < d.jurors.length; i++) {
            address juror = d.jurors[i];

            if (!d.hasVoted[juror]) {
                juryRegistry.slashJuror(juror); // Inactive juror
            } else if (d.vote[juror] == finalDecision) {
                juryRegistry.rewardJuror(juror); // Voted with majority
            } else {
                juryRegistry.slashJuror(juror); // Voted against majority
            }
        }

        emit DisputeResolved(disputeId, finalDecision);
    }

    ///********************************
    /// @dev Helper: check if address is among dispute jurors
    ///********************************
    function isJurorAssigned(uint256 disputeId, address juror) public view returns (bool) {
        address[] memory jList = disputes[disputeId].jurors;
        for (uint256 i = 0; i < jList.length; i++) {
            if (jList[i] == juror) return true;
        }
        return false;
    }
}
