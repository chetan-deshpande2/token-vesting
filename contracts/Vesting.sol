// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Vesting is Ownable {
     using SafeERC20 for IERC20; 
    using SafeMath for uint256;

    // uint256 advisorAllowance = 5;
    // uint256 partnershipsAllowance = 0;
    // uint256 mentorsAllowance = 7;

    uint256 private cliff;
    uint256 private start;
    uint256  public duration;



 /**
   @notice cliff period and time 
 **/
 


    enum Roles {
        Advisers,
         Partnetship ,
         Mentors
    }



    struct VestingSchedule {
       bool initialized;
        address beneficiary;
        uint256 intervalPeriod;
        bool revocable;
        uint256 amountTotal;
        uint256 released;
        uint256 tgeAmount;
        bool revoked;
    }

    mapping(address=>VestingSchedule) public advisersVesingSchedule;
    mapping(address=>VestingSchedule) public partnersVestingSchedule;
    mapping(address=>VestingSchedule ) public mentorsVestingSchedule;

    IERC20 private token;
    

    constructor( address _token) {
        require(_token != address(0x0),"invalid token address");
        token =   IERC20(_token);

    }


}
