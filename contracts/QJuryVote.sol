// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

///********************************
/// @title QJury Voting Contract
/// @author Farshad Baharvand
/// @notice Handles voting logic for selected jurors in a dispute
/// @dev Relies on external registry and dispute contracts
///********************************

contract QJuryVote {
    ///********************************
    /// @dev Vote options for a dispute
    ///********************************
    enum VoteOption {
        None,
        Yes,
        No,
        Abstain
    }

    struct Vote {
        address juror;
        VoteOption choice;
        bool hasVoted;
    }

    mapping(uint256 => mapping(address => Vote)) public disputeVotes; // disputeId => juror => vote
    mapping(uint256 => address[]) public disputeJurors;              // disputeId => juror list

    address public disputeContract;

    event JurorVoted(uint256 indexed disputeId, address indexed juror, VoteOption choice);

    modifier onlyDisputeContract() {
        require(msg.sender == disputeContract, "Only dispute contract can call this");
        _;
    }

    ///********************************
    /// @notice Set the dispute contract address (once)
    ///********************************
    constructor(address _disputeContract) {
        disputeContract = _disputeContract;
    }

    ///********************************
    /// @notice Assign selected jurors to a dispute
    /// @dev Called by dispute contract after juror selection
    /// @param disputeId ID of the dispute
    /// @param jurors List of selected jurors
    ///********************************
    function assignJurors(uint256 disputeId, address[] memory jurors) external onlyDisputeContract {
        disputeJurors[disputeId] = jurors;
        for (uint256 i = 0; i < jurors.length; i++) {
            disputeVotes[disputeId][jurors[i]] = Vote({
                juror: jurors[i],
                choice: VoteOption.None,
                hasVoted: false
            });
        }
    }

    ///********************************
    /// @notice Cast vote for a dispute
    /// @param disputeId ID of the dispute
    /// @param choice VoteOption: Yes / No / Abstain
    ///********************************
    function castVote(uint256 disputeId, VoteOption choice) external {
        require(choice != VoteOption.None, "Invalid vote option");
        require(disputeVotes[disputeId][msg.sender].juror == msg.sender, "You are not a juror");
        require(!disputeVotes[disputeId][msg.sender].hasVoted, "Already voted");

        disputeVotes[disputeId][msg.sender].choice = choice;
        disputeVotes[disputeId][msg.sender].hasVoted = true;

        emit JurorVoted(disputeId, msg.sender, choice);
    }

    ///********************************
    /// @notice Get all juror votes for a dispute (off-chain indexing)
    /// @param disputeId ID of the dispute
    ///********************************
    function getJurorVotes(uint256 disputeId) external view returns (Vote[] memory votes) {
        address[] memory jurors = disputeJurors[disputeId];
        votes = new Vote[](jurors.length);

        for (uint256 i = 0; i < jurors.length; i++) {
            votes[i] = disputeVotes[disputeId][jurors[i]];
        }
    }
}
