// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

///********************************
/// @title Jury Registry Contract
/// @author Farshad Baharvand
/// @notice A smart contract for registering jurors and managing staking logic
/// @dev Admin can reward or penalize jurors based on vote behavior
///********************************

contract JuryRegistry {
    ///********************************
    /// @dev Juror struct: holds stake and registration status
    ///********************************
    struct Juror {
        uint256 stakeAmount;   // Amount of ETH staked
        bool isRegistered;     // True if juror has registered
        bool hasStaked;        // True if juror has already staked
    }

    mapping(address => Juror) public jurors; // Juror registry
    address public admin;                    // Admin of the contract
    uint256 public minStake;                 // Minimum required stake in wei

    ///********************************
    /// @dev Events for logging state changes
    ///********************************
    event JurorRegistered(address indexed juror);
    event StakeDeposited(address indexed juror, uint256 amount);
    event StakeWithdrawn(address indexed juror, uint256 amount);

    ///********************************
    /// @notice Constructor sets the minimum stake and admin
    /// @param _minStake Minimum ETH stake required to become juror
    ///********************************
    constructor(uint256 _minStake) {
        admin = msg.sender;
        minStake = _minStake;
    }

    ///********************************
    /// @notice Register the sender as a juror
    /// @dev Can only be called once per address
    ///********************************
    function registerAsJuror() external {
        require(!jurors[msg.sender].isRegistered, "You are already registered.");
        jurors[msg.sender].isRegistered = true;
        emit JurorRegistered(msg.sender);
    }

    ///********************************
    /// @notice Deposit ETH as juror stake
    /// @dev Requires prior registration and exact stake amount
    ///********************************
    function depositStake() external payable {
        require(jurors[msg.sender].isRegistered, "You must register first.");
        require(msg.value >= minStake, "Stake amount too low.");
        require(!jurors[msg.sender].hasStaked, "Stake already deposited.");

        jurors[msg.sender].stakeAmount = msg.value;
        jurors[msg.sender].hasStaked = true;

        emit StakeDeposited(msg.sender, msg.value);
    }

    ///********************************
    /// @notice Reward juror by refunding their stake
    /// @dev Admin-only; used after verifying honest behavior
    /// @param juror Address of the juror to reward
    ///********************************
    function rewardJuror(address juror) external {
        require(msg.sender == admin, "Only admin can reward jurors.");
        require(jurors[juror].hasStaked, "Juror has no stake to return.");

        uint256 amount = jurors[juror].stakeAmount;

        jurors[juror].stakeAmount = 0;
        jurors[juror].hasStaked = false;

        payable(juror).transfer(amount);
        emit StakeWithdrawn(juror, amount);
    }

    ///********************************
    /// @notice Penalize juror by slashing their stake
    /// @dev Admin-only; used for dishonest or inactive jurors
    /// @param juror Address of the juror to penalize
    ///********************************
    function slashJuror(address juror) external {
        require(msg.sender == admin, "Only admin can slash jurors.");
        require(jurors[juror].hasStaked, "Juror has no stake to slash.");

        jurors[juror].stakeAmount = 0;
        jurors[juror].hasStaked = false;

        emit StakeWithdrawn(juror, 0);
    }

    ///********************************
    /// @notice View total ETH held by the contract
    /// @return Contract's balance in wei
    ///********************************
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
