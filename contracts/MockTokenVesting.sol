// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Vesting.sol";

/*
  @notice MockTokenVesting
 WARNING: use only for testing and debugging purpose
 */

contract MockTokenVesting is Vesting {
    uint256 mockTime = 0;

    constructor(address _token) Vesting(_token) {}

    function setCurrentTime(uint256 _time) external {
        mockTime = _time;
    }

    function getCurrentTime() public  virtual  override view returns (uint256) {
        return mockTime;
    }
}
