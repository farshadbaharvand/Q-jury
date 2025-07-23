// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

///********************************
/// @title QRandom Mock Oracle
/// @author 
/// @notice Mock implementation of randomness provider for local testing
///********************************

contract QRandomMock {
    address public juryContract;
    uint256 public lastRequestId;
    uint256 private seed;

    event RandomnessRequested(uint256 requestId, address requester);
    event RandomnessFulfilled(uint256 requestId, uint256 randomValue);

    ///********************************
    /// @notice Constructor sets the target contract (e.g., QJuryDispute)
    ///********************************
    constructor(address _juryContract) {
        juryContract = _juryContract;
        seed = 1;
    }

    ///********************************
    /// @notice Generates pseudo-randomness and calls fulfillRandomness on target contract
    ///********************************
    function requestRandomness() external returns (uint256) {
        require(msg.sender == juryContract, "Only target contract can request randomness");

        lastRequestId += 1;

        uint256 randomValue = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed))) % 10000;
        seed = randomValue; // update seed for next round

        emit RandomnessRequested(lastRequestId, msg.sender);
        emit RandomnessFulfilled(lastRequestId, randomValue);

        // Call fulfillRandomness on target contract
        (bool success, ) = juryContract.call(
            abi.encodeWithSignature("fulfillRandomness(uint256,uint256)", lastRequestId, randomValue)
        );
        require(success, "Callback to fulfillRandomness failed");

        return lastRequestId;
    }
}
