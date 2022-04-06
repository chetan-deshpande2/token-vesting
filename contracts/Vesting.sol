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

    uint256 private advisorAllowance = 5;
    uint256 private partnershipsAllowance;
    uint256 private mentorsAllowance = 7;

    // @notice variables to keep count of total tokens in the contract
    uint256 public contractBalance;
    uint256 public withdrwableAmount;

    // @notice tracking beneficiary count
    uint256 public advisersAndPartnershipsBeneficiariesCount = 0;
    uint256 public marketingBeneficiariesCount = 0;
    uint256 public reserveFundsBeneficiariesCount = 0;

    /*
@notice vesting schedule for beneficiaries
*/
    struct VestingSchedule {
        bool initialized;
        address beneficiary;
        uint256 cliff;
        uint256 start;
        uint256 duration;
        uint256 intervalPeriod;
        bool revocable;
        uint256 amountTotal;
        uint256 released;
        uint256 tgeAmount;
        bool revoked;
    }

    enum Roles {
        Advisers,
        Partnetship,
        Mentors
    }

    // @notice total number of holders

    mapping(address => uint256) private _holdersVestingCount;

    /// @notice vesting schedule ID to track vesting
    bytes32[] private _vestingSchedulesIds;

    //  @notice vesting schedule for  advisors partners and investors

    mapping(bytes32 => VestingSchedule) public advisersVesingSchedule;
    mapping(bytes32 => VestingSchedule) public partnersVestingSchedule;
    mapping(bytes32 => VestingSchedule) public mentorsVestingSchedule;

    IERC20 private token;

    constructor(address _token) {
        require(_token != address(0x0), "invalid token address");
        token = IERC20(_token);
    }

    function createVestingSchedule(
        Roles role,
        address _beneficiary,
        uint256 _cliff,
        uint256 _start,
        uint256 _duration,
        uint256 _intervalPeriod,
        bool _revocable,
        uint256 _amount,
        bytes32 vestingScheduleId
    ) public {
        require(withdrwableAmount >= _amount, "Insufficent tokens ");
        uint256 cliff = _start + (_cliff);
        require(_duration > 0, "TokenVesting: duration must be > 0");
        require(_amount > 0, "TokenVesting: amount must be > 0");
        require(
            _intervalPeriod >= 1,
            "TokenVesting: slicePeriodSeconds must be >= 1"
        );
        require(
            role == Roles.Advisers ||
                role == Roles.Mentors ||
                role == Roles.Partnetship,
            "Roles Must be 0 or 1"
        );
        vestingScheduleId = this.computeNextVestingScheduleIdForHolder(
            _beneficiary
        );
        creatingSchedule(
            role,
            _beneficiary,
            cliff,
            _start,
            _duration,
            _intervalPeriod,
            _revocable,
            _amount,
            vestingScheduleId
        );
        _vestingSchedulesIds.push(vestingScheduleId);
        uint256 currentVestingCount = _holdersVestingCount[_beneficiary];
        _holdersVestingCount[_beneficiary] = currentVestingCount + (1);
    }

    function creatingSchedule(
        Roles roles,
        address _beneficiary,
        uint256 _cliff,
        uint256 _start,
        uint256 _duration,
        uint256 _intervalPeriod,
        bool _revocable,
        uint256 _amount,
        bytes32 vestingScheduleId
    ) internal {
        if (roles == Roles.Advisers) {
            uint256 _tgeAmount = (_amount * advisorAllowance) / (100);
            uint256 _extraTime = _intervalPeriod / 4;
            uint256 _timeFrame = _extraTime + _intervalPeriod;
            _duration = _timeFrame;
            advisersVesingSchedule[vestingScheduleId] = VestingSchedule(
                true,
                _beneficiary,
                _cliff,
                _start,
                _duration,
                _intervalPeriod,
                _revocable,
                _amount,
                0,
                _tgeAmount,
                false
            );
        } else if (roles == Roles.Partnetship) {
            uint256 _tgeAmount = 0;
            uint256 _extraTime = _intervalPeriod / (4);
            uint256 _timeFrame = _extraTime + (_intervalPeriod);
            _duration = _timeFrame;
            partnersVestingSchedule[vestingScheduleId] = VestingSchedule(
                true,
                _beneficiary,
                _cliff,
                _start,
                _duration,
                _intervalPeriod,
                _revocable,
                _amount,
                0,
                _tgeAmount,
                false
            );
        } else if (roles == Roles.Mentors) {
            uint256 _tgeAmount = (_amount * mentorsAllowance) / (100);
            _amount = _amount - (_tgeAmount);
            uint256 _extraTime = _duration / (4);
            uint256 _timeFrame = _extraTime + (_duration);
            _duration = _timeFrame;
            mentorsVestingSchedule[vestingScheduleId] = VestingSchedule(
                true,
                _beneficiary,
                _cliff,
                _start,
                _duration,
                _intervalPeriod,
                _revocable,
                _amount,
                0,
                _tgeAmount,
                false
            );
        }
    }

    function computeNextVestingScheduleIdForHolder(address holder)
        public
        view
        returns (bytes32)
    {
        return
            computeVestingScheduleIdForAddressAndIndex(
                holder,
                _holdersVestingCount[holder]
            );
    }

    /**
     * @dev Computes the vesting schedule identifier for an address and an index.
     */

    function computeVestingScheduleIdForAddressAndIndex(
        address holder,
        uint256 index
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(holder, index));
    }


}
