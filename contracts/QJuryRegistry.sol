// === QJuryRegistry.sol ===
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

/// @title Jury Registry Contract
/// @author Farshad Baharvand
/// @notice A smart contract for registering jurors

contract QJuryRegistry {
    uint256 public constant STAKE_AMOUNT = 0.1 ether;

    mapping(address => bool) public isJuror;
    mapping(address => uint256) public stakes;
    address[] public jurors;

    event JurorRegistered(address indexed juror);
    event JurorSlashed(address indexed juror);
    event JurorRewarded(address indexed juror, uint256 amount);

    function registerAsJuror() external payable {
        require(!isJuror[msg.sender], "Already registered");
        require(msg.value == STAKE_AMOUNT, "Incorrect stake");

        isJuror[msg.sender] = true;
        stakes[msg.sender] = msg.value;
        jurors.push(msg.sender);

        emit JurorRegistered(msg.sender);
    }

    function getAllJurors() external view returns (address[] memory) {
        return jurors;
    }

    function slashJuror(address juror) external {
        require(isJuror[juror], "Not a juror");
        stakes[juror] = 0;
        isJuror[juror] = false;
        emit JurorSlashed(juror);
    }

    function rewardJuror(address juror, uint256 amount) external {
        require(isJuror[juror], "Not a juror");
        payable(juror).transfer(amount);
        emit JurorRewarded(juror, amount);
    }

    receive() external payable {}
}
