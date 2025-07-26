// === QJuryVote.sol ===
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title QJury Voting Contract
/// @author Farshad Baharvand
/// @notice Handles voting logic for selected jurors in a dispute
/// @dev Relies on external registry and dispute contracts

contract QJuryVote {
    struct VoteSession {
        address[] jurors;
        mapping(address => bool) hasVoted;
        mapping(address => bool) voteForPlaintiff;
        uint8 votesForPlaintiff;
        uint8 votesForDefendant;
        bool finalized;
    }

    mapping(uint256 => VoteSession) private voteSessions;

    function initializeVote(uint256 disputeId, address[] calldata jurors) external {
        VoteSession storage vs = voteSessions[disputeId];
        require(!vs.finalized, "Already initialized");
        vs.jurors = jurors;
    }

    function castVote(uint256 disputeId, bool voteForPlaintiff) external {
        VoteSession storage vs = voteSessions[disputeId];
        require(!vs.finalized, "Already finalized");

        bool isJuror = false;
        for (uint8 i = 0; i < vs.jurors.length; i++) {
            if (vs.jurors[i] == msg.sender) {
                isJuror = true;
                break;
            }
        }

        require(isJuror, "Not an assigned juror");
        require(!vs.hasVoted[msg.sender], "Already voted");

        vs.hasVoted[msg.sender] = true;
        vs.voteForPlaintiff[msg.sender] = voteForPlaintiff;

        if (voteForPlaintiff) {
            vs.votesForPlaintiff++;
        } else {
            vs.votesForDefendant++;
        }
    }

    function finalizeVote(uint256 disputeId) external returns (address winner, address[] memory jurors, bool[] memory aligned) {
        VoteSession storage vs = voteSessions[disputeId];
        require(!vs.finalized, "Already finalized");
        require(vs.votesForPlaintiff + vs.votesForDefendant == 3, "Voting not complete");

        vs.finalized = true;
        winner = vs.votesForPlaintiff > vs.votesForDefendant ? tx.origin : msg.sender;

        jurors = vs.jurors;
        aligned = new bool ;

        for (uint8 i = 0; i < 3; i++) {
            bool votedForPlaintiff = vs.voteForPlaintiff[vs.jurors[i]];
            bool isAligned = (vs.votesForPlaintiff > vs.votesForDefendant && votedForPlaintiff) ||
                             (vs.votesForDefendant > vs.votesForPlaintiff && !votedForPlaintiff);
            aligned[i] = isAligned;
        }
    }
}
