// === QJuryDispute.sol ===
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import "./QJuryRegistry.sol";
import "./QJuryVote.sol";
import "./QJuryReward.sol";

/// @title QJuryDispute Contract
/// @notice Handles voting and resolution for disputes assigned to jurors
/// @dev Works with JuryRegistry contract for reward/slash logic

contract QJuryDispute {
    enum DisputeStatus { Pending, Resolved }

    struct Dispute {
        uint256 id;
        address plaintiff;
        address defendant;
        address[] jurors;
        DisputeStatus status;
        address winner;
    }

    uint256 public nextDisputeId;
    mapping(uint256 => Dispute) public disputes;

    QJuryRegistry public registry;
    QJuryVote public voteContract;
    QJuryReward public rewardContract;
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    event DisputeCreated(uint256 indexed disputeId, address indexed plaintiff, address indexed defendant, address[] jurors);
    event DisputeResolved(uint256 indexed disputeId, address winner);

    constructor(address _registry, address _vote, address _reward) {
        registry = QJuryRegistry(_registry);
        voteContract = QJuryVote(_vote);
        rewardContract = QJuryReward(_reward);
        owner = msg.sender;
    }

    function createDispute(address defendant, address[] calldata assignedJurors) external onlyOwner {
        require(defendant != address(0), "Invalid defendant");
        require(assignedJurors.length == 3, "Exactly 3 jurors required");

        for (uint8 i = 0; i < 3; i++) {
            require(registry.isJuror(assignedJurors[i]), "Juror not registered");
        }

        Dispute storage dispute = disputes[nextDisputeId];
        dispute.id = nextDisputeId;
        dispute.plaintiff = msg.sender;
        dispute.defendant = defendant;
        dispute.jurors = assignedJurors;
        dispute.status = DisputeStatus.Pending;

        voteContract.initializeVote(nextDisputeId, assignedJurors);
        emit DisputeCreated(nextDisputeId, msg.sender, defendant, assignedJurors);
        nextDisputeId++;
    }

    function finalizeDispute(uint256 disputeId) external {
        require(disputes[disputeId].status == DisputeStatus.Pending, "Already resolved");

        (address winner, address[] memory jurors, bool[] memory aligned) = voteContract.finalizeVote(disputeId);
        disputes[disputeId].winner = winner;
        disputes[disputeId].status = DisputeStatus.Resolved;

        for (uint8 i = 0; i < jurors.length; i++) {
            if (aligned[i]) {
                rewardContract.reward(jurors[i]);
            } else {
                rewardContract.slash(jurors[i]);
            }
        }

        emit DisputeResolved(disputeId, winner);
    }
}
