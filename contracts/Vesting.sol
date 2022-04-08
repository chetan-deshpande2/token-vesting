// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Vesting is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // @notice tracking beneficiary count
    uint256 public advisersBeneficiariesCount = 0;
    uint256 public partnersBeneficiariesCount = 0;
    uint256 public mentorsBeneficiariesCount = 0;

    //@notice variables for TEG
    uint256 public mentorsTEG;
    uint256 public advisorsTEG;

    //@notice variables to keep count of total tokens in the contract
    uint256 public totalTokenInContract;
    uint256 public totalWithdrawableAmount;

    //@notice total Token each division has
    uint256 public totalAmountForAdvisors;
    uint256 public totalAmountForPartners;
    uint256 public totalAmountForMentors;

    //@notice tokens that can be vested .
    uint256 public advisorsVestingPool;
    uint256 public partnersVestingPool;
    uint256 mentorsVestingPool;

    /*
    @notice create vesting schedule for benificireis
    @param beneficiary of tokens after they are released
    @param cliff period in seconds
    @param start time of the vesting period
    @param duration for the vesting period in seconds
    @param  slicePeriodSeconds for the duration of slicePeriodSeconds in vesting Schedule
    @param revocable for weather or not the vesting is revokable
    @param amountTotal for total amount of the tokens that can be released  at the end of the vesting
    @param released for amount of token released
    @param tgeAmount for tge after vesting schedule created
    @param revoked for weather or not vesting schedule has been revoked

    */

    struct VestingSchedule {
        bool initialized;
        address beneficiary;
        uint256 cliff;
        uint256 start;
        uint256 duration;
        uint256 slicePeriodSeconds;
        bool revocable;
        uint256 amountTotal;
        uint256 released;
        uint256 tgeAmount;
        bool revoked;
    }

    //@notice to check holders vesting count
    mapping(address => uint256) private holdersVestingCount;

    //@notice vesting Schedueles for different roles
    mapping(bytes32 => VestingSchedule) private vestingScheduleForAdvisors;
    mapping(bytes32 => VestingSchedule) private vestingScheduleForPartners;
    mapping(bytes32 => VestingSchedule) private vestingScheduleForMentors;

    //@notice keeping track of benificiries in different role
    mapping(address => bool) private advisorsBenificiaries;
    mapping(address => bool) private partnersBeneficiaries;
    mapping(address => bool) private mentorsBeneficiaries;

    //@notice vesting schedule ID to track vesting
    bytes32[] private vestingScheduleIds;

    //@notice all the roles
    enum Roles {
        Advisors,
        Partners,
        Mentors
    }

    //@param for storing the token address for ERC20 token
    IERC20 private token;

    /*
    @dev revert if no vesting schedule matches the past identifier
    @param vestingScheduleId  to know the vesting schedule details that were created
    @param role to know the role of the vesting schedule that is created;
    */
    modifier onlyIfVestingScheduleExists(
        bytes32 vestingScheduleId,
        Roles role
    ) {
        if (role == Roles.Advisors) {
            require(
                vestingScheduleForAdvisors[vestingScheduleId].initialized ==
                    true
            );
        } else if (role == Roles.Partners) {
            require(
                vestingScheduleForPartners[vestingScheduleId].initialized ==
                    true
            );
        } else if (role == Roles.Mentors) {
            require(
                vestingScheduleForMentors[vestingScheduleId].initialized == true
            );
        }
        _;
    }

    /*
    @dev revert if vesting schedule does not exists or  has been revoked
    @param vestingScheduleId  to know the vesting schedule details that were created
    @param role to know the role of the vesting schedule that is created
     */
    modifier onlyIfVestingScheduleNotRevoked(
        bytes32 vestingScheduleId,
        Roles role
    ) {
        if (role == Roles.Advisors) {
            require(
                vestingScheduleForAdvisors[vestingScheduleId].initialized ==
                    true
            );
            require(
                vestingScheduleForAdvisors[vestingScheduleId].revoked == false
            );
        } else if (role == Roles.Partners) {
            require(
                vestingScheduleForPartners[vestingScheduleId].initialized ==
                    true
            );
            require(
                vestingScheduleForPartners[vestingScheduleId].revoked == false
            );
        } else if (role == Roles.Mentors) {
            require(
                vestingScheduleForMentors[vestingScheduleId].initialized == true
            );
            require(
                vestingScheduleForMentors[vestingScheduleId].revoked == false
            );
        }
        _;
    }

    //@param _token address of the ERC20 token contract
    constructor(address _token) {
        require(_token != address(0x0));
        token = IERC20(_token);
    }

    // @notice function to return current Time
    function getCurrentTime() public view returns (uint256) {
        return block.timestamp;
    }

    //@notice to update the total supply of tokens in the contract
    function upadateTotalSupply() internal onlyOwner {
        totalTokenInContract = token.balanceOf(address(this));
    }

    //@notice function to update withdrawable balance
    function updateTotalWithdrawableAmount() internal onlyOwner {
        uint256 reservedAmount = totalAmountForAdvisors +
            totalAmountForMentors +
            totalAmountForPartners;
        totalWithdrawableAmount =
            token.balanceOf(address(this)) -
            reservedAmount;
    }

    /*
   @notice update the benificiary count
   @param _address that is address of the benificiary
   @param role  the role of the benificiary
   */
    function addBenificiary(address _address, Roles role) internal onlyOwner {
        if (role == Roles.Advisors) {
            advisersBeneficiariesCount++;
            advisorsBenificiaries[_address] = true;
        } else if (role == Roles.Partners) {
            partnersBeneficiariesCount++;
            partnersBeneficiaries[_address] = true;
        } else if (role == Roles.Mentors) {
            mentorsBeneficiariesCount++;
            mentorsBeneficiaries[_address] = true;
        }
    }

    /*
    @notice  this function is used to create vesting Schedule
    @param role  to decide role of benificiary
    @param _beneficiary of tokens after they are released
    @param _cliff period in seconds
    @param _start time of the vesting period
    @param _duration for the vesting period in seconds
    @param  _slicePeriodSeconds for the duration of slicePeriodSeconds in vesting Schedule
    @param _revocable for weather or not the vesting is revokable
    @param _amount for total amount of the tokens given to the vesting schedule
    */
    function createVestingSchedule(
        Roles role,
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        bool _revocable,
        uint256 _amount
    ) public onlyOwner {
        require(
            this.getWithdrawableAmount() >= 0,
            "Token Vesting : cannot cretae vesting schedule because  not sufficent tokens "
        );
        require(
            _duration > 0,
            "Token Vesting: duration must be greater than 0"
        );
        require(
            _slicePeriodSeconds >= 1,
            "Token Vesting: slice PeriodsSeconds must be >=1 "
        );
        require(
            role == Roles.Advisors ||
                role == Roles.Partners ||
                role == Roles.Mentors,
            "Token vesting : roles must be 0 or 1"
        );
        bytes32 vestingScheduleId = this.computeNextVestingScheduleIdForHolder(
            _beneficiary
        );
        conditionForCreatingVestingSchedule(
            role,
            _beneficiary,
            _cliff,
            _start,
            _duration,
            _slicePeriodSeconds,
            _revocable,
            _amount,
            vestingScheduleId
        );
        addBenificiary(_beneficiary, role);
        vestingScheduleIds.push(vestingScheduleId);
        uint256 currentVestingCount = holdersVestingCount[_beneficiary];
        holdersVestingCount[_beneficiary] = currentVestingCount + 1;
    }

    //@return to get the total withdrawable amount
    function getWithdrawableAmount() public view returns (uint256) {
        return totalWithdrawableAmount;
    }

    /*
    @devComputes the next vesting schedule identifier for a given holder address.
    @param holder is input address
    @return the next vesting schedule ID for  holder
    */
    function computeNextVestingScheduleIdForHolder(address holder)
        public
        view
        returns (bytes32)
    {
        return
            computeVestingScheduleIdForAddressAndIndex(
                holder,
                holdersVestingCount[holder]
            );
    }

    /*
    @param holder is the address of the holder of the account
     @param index is the index of the different vesting schdules held by the address
    @return vesting schedule ID for a particular index of an address
    */
    function computeVestingScheduleIdForAddressAndIndex(
        address holder,
        uint256 index
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(holder, index));
    }

    /*
    @notice to check the conditions while creating vesting schedule
    @dev timeInterval is used to divide the given time into equla distibution during vesting schedule
    @param vestingScheduleId for creating the perticular vesting Schedule
    @param _revocable to decide the if the benificiary vesting schedule can be revoked

    */
    function conditionForCreatingVestingSchedule(
        Roles role,
        address _beneficiary,
        uint256 _cliff,
        uint256 _start,
        uint256 _duration,
        uint256 _intervalPeriod,
        bool _revocable,
        uint256 _amount,
        bytes32 vestingScheduleId
    ) internal {
        if (role == Roles.Advisors) {
            uint256 tgeAmount = (_amount * advisorsTEG) / 100;
            uint256 extraTime = _intervalPeriod / 2;
            uint256 timeInterval = extraTime + _intervalPeriod;
            _duration = timeInterval;
            vestingScheduleForAdvisors[vestingScheduleId] = VestingSchedule(
                true,
                _beneficiary,
                _cliff,
                _start,
                _duration,
                _intervalPeriod,
                _revocable,
                _amount,
                0,
                tgeAmount,
                false
            );
        } else if (role == Roles.Partners) {
            uint256 tgeAmount = 0;
            _amount = _amount - (tgeAmount);
            uint256 extraTime = _intervalPeriod / 2;
            uint256 timeInterval = extraTime + _intervalPeriod;
            _duration = timeInterval;
            vestingScheduleForPartners[vestingScheduleId] = VestingSchedule(
                true,
                _beneficiary,
                _cliff,
                _start,
                _duration,
                _intervalPeriod,
                _revocable,
                _amount,
                0,
                tgeAmount,
                false
            );
        } else if (role == Roles.Mentors) {
            uint256 tgeAmount = (_amount * mentorsTEG) / 100;
            uint256 extraTime = _intervalPeriod / 2;
            uint256 timeInterval = extraTime + _intervalPeriod;
            _duration = timeInterval;
            vestingScheduleForMentors[vestingScheduleId] = VestingSchedule(
                true,
                _beneficiary,
                _cliff,
                _start,
                _duration,
                _intervalPeriod,
                _revocable,
                _amount,
                0,
                tgeAmount,
                false
            );
        }
    }

    /*
    @notice revoke the vesting schedule  of perticular holder
    @param vestingScheduleId the vesting schedular identifier
    @role  to find the role of holder
    */

    function revoke(bytes32 vestingScheduleId, Roles role)
        public
        onlyOwner
        onlyIfVestingScheduleNotRevoked(vestingScheduleId, role)
    {
        if (role == Roles.Advisors) {
            VestingSchedule
                storage vestingSchedule = vestingScheduleForAdvisors[
                    vestingScheduleId
                ];
            require(
                vestingSchedule.revocable == true,
                "Token Vesting : vesting is not revokable"
            );
            uint256 vestedAmount = computeReleasableAmount(
                vestingSchedule,
                role
            );
            if (vestedAmount > 0) {
                vestingSchedule.revoked == true;
                uint256 unreleased = vestingSchedule.amountTotal -
                    (vestingSchedule.released);
                totalAmountForAdvisors = totalAmountForAdvisors - unreleased;
            }
        } else if (role == Roles.Partners) {
            VestingSchedule
                storage vestingSchedule = vestingScheduleForPartners[
                    vestingScheduleId
                ];
            require(
                vestingSchedule.revocable == true,
                "Token Vesting : vesting is not revokable"
            );
            uint256 vestedAmount = computeReleasableAmount(
                vestingSchedule,
                role
            );
            if (vestedAmount > 0) {
                vestingSchedule.revoked == true;
                uint256 unreleased = vestingSchedule.amountTotal -
                    (vestingSchedule.released);
                totalAmountForAdvisors = totalAmountForAdvisors - unreleased;
            }
        }
        if (role == Roles.Mentors) {
            VestingSchedule storage vestingSchedule = vestingScheduleForMentors[
                vestingScheduleId
            ];
            require(
                vestingSchedule.revocable == true,
                "Token Vesting : vesting is not revokable"
            );
            uint256 vestedAmount = computeReleasableAmount(
                vestingSchedule,
                role
            );
            if (vestedAmount > 0) {
                vestingSchedule.revoked == true;
                uint256 unreleased = vestingSchedule.amountTotal -
                    (vestingSchedule.released);
                totalAmountForAdvisors = totalAmountForAdvisors - unreleased;
            }
        }
    }

    /*
    @notice calculating the total release amount
     @param vestingSchedule is to send in the details of the vesting schedule created
     @param r is the role of the beneficiary
     @return the calculated releaseable amount depending on the role
     */
    function computeReleasableAmount(
        VestingSchedule memory vestingSchedule,
        Roles role
    ) internal view returns (uint256) {
        uint256 currentTime = getCurrentTime();
        if (
            role == Roles.Advisors ||
            role == Roles.Partners ||
            role == Roles.Mentors
        ) {
            if (
                currentTime < vestingSchedule.cliff ||
                vestingSchedule.revoked == true
            ) {
                return 0;
            } else if (
                currentTime >=
                vestingSchedule.start + (vestingSchedule.duration)
            ) {
                return vestingSchedule.amountTotal - (vestingSchedule.released);
            } else {
                uint256 cliffTimeEnd = vestingSchedule.cliff;
                uint256 timeFromStart = currentTime - (cliffTimeEnd);
                uint256 timePerInterval = vestingSchedule.slicePeriodSeconds;
                uint256 vestedIntervalPeriods = timeFromStart /
                    (timePerInterval);
                uint256 vestedTime = vestedIntervalPeriods * (timePerInterval);
                uint256 vestedAmount = ((vestingSchedule.amountTotal) *
                    (vestedTime)) / (vestingSchedule.duration);
                vestedAmount = vestedAmount - (vestingSchedule.released);
                return vestedAmount;
            }
        }
    }

  }
