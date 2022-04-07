// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Vesting is Ownable, ReentrancyGuard {
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

    mapping(address => uint256) private holdersVestingCount;

    /// @notice vesting schedule ID to track vesting
    bytes32[] private _vestingSchedulesIds;

    //  @notice vesting schedule for  advisors partners and investors

    mapping(bytes32 => VestingSchedule) public advisersVesingSchedule;
    mapping(bytes32 => VestingSchedule) public partnersVestingSchedule;
    mapping(bytes32 => VestingSchedule) public mentorsVestingSchedule;

    IERC20 private token;

    modifier onlyIfVestingScheduleExists(
        bytes32 vestingScheduleId,
        Roles role
    ) {
        if (role == Roles.Advisers) {
            require(
                advisersVesingSchedule[vestingScheduleId].initialized == true
            );
        } else if (role == Roles.Partnetship) {
            require(
                partnersVestingSchedule[vestingScheduleId].initialized == true
            );
        } else if (role == Roles.Mentors) {
            require(
                mentorsVestingSchedule[vestingScheduleId].initialized == true
            );
        }
        _;
    }

    modifier onlyIfVestingScheduleNotRevoked(
        bytes32 vestingScheduleId,
        Roles role
    ) {
        if (role == Roles.Advisers) {
            require(
                advisersVesingSchedule[vestingScheduleId].initialized == true
            );
            require(advisersVesingSchedule[vestingScheduleId].revoked == false);
        } else if (role == Roles.Partnetship) {
            require(
                partnersVestingSchedule[vestingScheduleId].initialized == true
            );
            require(
                partnersVestingSchedule[vestingScheduleId].revoked == false
            );
        } else if (role == Roles.Mentors) {
            require(
                mentorsVestingSchedule[vestingScheduleId].initialized == true
            );
            require(mentorsVestingSchedule[vestingScheduleId].revoked == false);
        }
        _;
    }

    constructor(address _token) {
        require(_token != address(0x0), "invalid token address");
        token = IERC20(_token);
    }

    /// @param _beneficiary is the address of the beneficiary
    /// @return the vesting schedule count by beneficiary
    function getVestingSchedulesCountByBeneficiary(address _beneficiary)
        external
        view
        returns (uint256)
    {
        return holdersVestingCount[_beneficiary];
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
        uint256 currentVestingCount = holdersVestingCount[_beneficiary];
        holdersVestingCount[_beneficiary] = currentVestingCount + (1);
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
                holdersVestingCount[holder]
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

    function getCurrentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function release(
        bytes32 vestingScheduleId,
        uint256 amount,
        Roles role
    ) public nonReentrant {
        VestingSchedule memory vestingSchedule;
        if (role == Roles.Advisers) {
            vestingSchedule = advisersVesingSchedule[vestingScheduleId];
        } else if (role == Roles.Partnetship) {
            vestingSchedule = partnersVestingSchedule[vestingScheduleId];
        } else if (role == Roles.Mentors) {
            vestingSchedule = mentorsVestingSchedule[vestingScheduleId];
        }

        bool isBeneficiary = msg.sender == vestingSchedule.beneficiary;
        uint256 currentTime = getCurrentTime();
        require(
            isBeneficiary,
            "TokenVesting: only beneficiary and owner can release vested tokens"
        );
        vestingSchedule.released = vestingSchedule.released + (amount);
        address payable beneficiaryPayable = payable(
            vestingSchedule.beneficiary
        );
        if (role == Roles.Advisers) {
            advisorAllowance = advisorAllowance - (amount);
        } else if (role == Roles.Partnetship) {
            if (currentTime < vestingSchedule.cliff) {
                vestingSchedule.tgeAmount =
                    vestingSchedule.tgeAmount -
                    (amount);
                vestingSchedule.released = vestingSchedule.released - (amount);
            } else {
                partnershipsAllowance = partnershipsAllowance - (amount);
            }
        } else {
            mentorsAllowance = mentorsAllowance - (amount);
        }

        token.safeTransfer(beneficiaryPayable, amount);
    }

    function _computeReleasableAmount(
        VestingSchedule memory vestingSchedule,
        Roles role
    ) internal view returns (uint256) {
        uint256 currentTime = getCurrentTime();
        if (role == Roles.Advisers) {
            if (currentTime < vestingSchedule.cliff) {
                return 0;
            } else if (
                currentTime >=
                vestingSchedule.start + (vestingSchedule.duration)
            ) {
                return vestingSchedule.amountTotal - (vestingSchedule.released);
            } else {
                uint256 cliffTimeEnd = vestingSchedule.cliff;
                uint256 timeFromStart = currentTime - (cliffTimeEnd);
                uint256 timePerInterval = vestingSchedule.intervalPeriod;
                uint256 vestedIntervalPeriods = timeFromStart /
                    (timePerInterval);
                uint256 vestedTime = vestedIntervalPeriods * (timePerInterval);
                uint256 vestedAmount = ((vestingSchedule.amountTotal) *
                    (vestedTime)) / (vestingSchedule.duration);
                vestedAmount = vestedAmount - (vestingSchedule.released);
                return vestedAmount;
            }
        } else if (role == Roles.Partnetship) {
            if (vestingSchedule.revoked == true) {
                return 0;
            }
            if (currentTime < vestingSchedule.cliff) {
                return vestingSchedule.tgeAmount;
            } else if (
                currentTime >=
                vestingSchedule.start + (vestingSchedule.duration)
            ) {
                return
                    (vestingSchedule.amountTotal +
                        (vestingSchedule.tgeAmount)) -
                    (vestingSchedule.released);
            } else {
                uint256 cliffTimeEnd = vestingSchedule.cliff;
                uint256 timeFromStart = currentTime - (cliffTimeEnd);
                uint256 timePerInterval = vestingSchedule.intervalPeriod;
                uint256 vestedIntervalPeriods = timeFromStart /
                    (timePerInterval);
                uint256 vestedTime = vestedIntervalPeriods * (timePerInterval);
                uint256 twentyPercentValue = ((vestingSchedule.amountTotal) *
                    (20)) / (100);
                uint256 vestedAmount = ((vestingSchedule.amountTotal) *
                    (vestedTime)) / (vestingSchedule.duration);
                vestedAmount =
                    (vestedAmount +
                        (twentyPercentValue) +
                        (vestingSchedule.tgeAmount)) -
                    (vestingSchedule.released);
                return vestedAmount;
            }
        } else if (role == Roles.Mentors) {
            if (
                (currentTime < vestingSchedule.cliff) ||
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
                uint256 timePerInterval = vestingSchedule.intervalPeriod;
                uint256 vestedIntervalPeriods = timeFromStart /
                    (timePerInterval);
                uint256 vestedTime = vestedIntervalPeriods * (timePerInterval);
                uint256 twentyPercentValue = (vestingSchedule.amountTotal *
                    (20)) / (100);
                uint256 vestedAmount = (vestingSchedule.amountTotal *
                    (vestedTime)) / (vestingSchedule.duration);
                vestedAmount =
                    (vestedAmount - (vestingSchedule.released)) +
                    (twentyPercentValue);
                return vestedAmount;
            }
        }
    }

    function revoke(bytes32 vestingScheduleId, Roles role) public {
        if (role == Roles.Advisers) {
            VestingSchedule storage vestingSchedule = advisersVesingSchedule[
                vestingScheduleId
            ];
            require(
                vestingSchedule.revocable == true,
                "TokenVesting: vesting is not revocable"
            );
            uint256 vestedAmount = _computeReleasableAmount(
                vestingSchedule,
                role
            );
            if (vestedAmount > 0) {
                vestingSchedule.revoked = true;
                uint256 unreleased = vestingSchedule.amountTotal -
                    (vestingSchedule.released);
                advisorAllowance = advisorAllowance - (unreleased);
                release(vestingScheduleId, vestedAmount, role);
            }
        } else if (role == Roles.Partnetship) {
            VestingSchedule storage vestingSchedule = partnersVestingSchedule[
                vestingScheduleId
            ];
            require(
                vestingSchedule.revocable == true,
                "TokenVesting: vesting is not revocable"
            );
            uint256 vestedAmount = _computeReleasableAmount(
                vestingSchedule,
                role
            );
            if (vestedAmount > 0) {
                vestingSchedule.revoked = true;
                uint256 unreleased = vestingSchedule.amountTotal -
                    (vestingSchedule.released);
                partnershipsAllowance = partnershipsAllowance - (unreleased);
                release(vestingScheduleId, vestedAmount, role);
            }
        } else if (role == Roles.Mentors) {
            VestingSchedule storage vestingSchedule = partnersVestingSchedule[
                vestingScheduleId
            ];
            require(
                vestingSchedule.revocable == true,
                "TokenVesting: vesting is not revocable"
            );
            uint256 vestedAmount = _computeReleasableAmount(
                vestingSchedule,
                role
            );
            if (vestedAmount > 0) {
                vestingSchedule.revoked = true;
                uint256 unreleased = vestingSchedule.amountTotal -
                    (vestingSchedule.released);
                mentorsAllowance = mentorsAllowance - (unreleased);
                release(vestingScheduleId, vestedAmount, role);
            }
        }
    }

    /**
     * @dev Returns the amount of tokens that can be withdrawn by the owner.
     * @return the amount of tokens
     */
    function getWithdrawableAmount() public view returns (uint256) {
        return token.balanceOf(address(this)) - (withdrwableAmount);
    }

    /**
     * @notice Withdraw the specified amount if possible.
     * @param amount the amount to withdraw
     */
    function withdraw(uint256 amount) public nonReentrant onlyOwner {
        require(
            this.getWithdrawableAmount() >= amount,
            "TokenVesting: not enough withdrawable funds"
        );
        token.safeTransfer(owner(), amount);
    }

    receive() external payable {}

    fallback() external payable {}
}
