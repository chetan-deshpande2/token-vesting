// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Vesting is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    //TGE for each role
    uint256 public companyReserveTGE;
    uint256 public equityInvestorTGE;
    uint256 public teamTGE;
    uint256 public exchageListingAndLiquidityTGE;
    uint256 public ecosystemTGE;
    uint256 public stakingAndRewardTGE;
    uint256 public airOrBurnTGE;
    uint256 public advisersAndPartnershipsTGE;

    //@notice total tokens each division has
    uint256 public vestingSchedulesTotalAmountForCompanyReserve;
    uint256 public vestingSchedulesTotalAmountForEquityInvestor;
    uint256 public vestingSchedulesTotalAmountForTeam;
    uint256 public vestingSchedulesTotalAmountForExchageListingAndLiquidity;
    uint256 public vestingSchedulesTotalAmountForEcosystem;
    uint256 public vestingSchedulesTotalAmountForStakingAndReward;
    uint256 public vestingSchedulesTotalAmountForAirOrBurn;
    uint256 public vestingSchedulesTotalAmountForAdvisersAndPartnership;

    //@notice variables to keep count of total tokens in contract
    uint256 public totalTokensInContract;
    uint256 public totalWithdrawableAmount;

    //@notice tokens that can be withdrawn any time
    uint256 public companyReserveTGEPool;
    uint256 public equityInvestorTGEPool;
    uint256 public teamTGEPool;
    uint256 public exchageListingAndLiquidityTGEPool;
    uint256 public ecosystemTGEPool;
    uint256 public stakingAndRewardTGEPool;
    uint256 public airOrBurnTGEPool;
    uint256 public advisersAndPartnershipsTGEPool;

    //@notice tokens that can be vested
    uint256 public companyReserveVestingPool;
    uint256 public equityInvestorVestingPool;
    uint256 public teamVestingPool;
    uint256 public exchageListingAndLiquidityVestingPool;
    uint256 public ecosystemVestingPool;
    uint256 public stakingAndRewardVestingPool;
    uint256 public airOrBurnVestingPool;
    uint256 public advisersAndPartnershipsVestingPool;

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

    // @notice tracking beneficiary count
    uint256 public CompanyReserveBeneficiariesCount = 0;
    uint256 public EquityInvestorBeneficiariesCount = 0;
    uint256 public TeamBeneficiariesCount = 0;
    uint256 public ExchageListingAndLiquidityBeneficiariesCount = 0;
    uint256 public EcosystemBeneficiariesCount = 0;
    uint256 public StakingAndRewardBeneficiariesCount = 0;
    uint256 public AirOrBurnBeneficiariesCount = 0;
    uint256 public AdvisersAndPartnershipsBeneficiariesCount = 0;

    //@notice to check holders vesting count
    mapping(address => uint256) private holdersVestingCount;

    //@notice vesting Schedueles for different roles
    mapping(bytes32 => VestingSchedule)
        private vestingScheduleForCompanyReserve;
    mapping(bytes32 => VestingSchedule)
        private vestingScheduleForEquityInvestor;
    mapping(bytes32 => VestingSchedule) private vestingScheduleForTeam;
    mapping(bytes32 => VestingSchedule)
        private vestingScheduleForExchageListingAndLiquidity;
    mapping(bytes32 => VestingSchedule) private vestingScheduleForEcosystem;
    mapping(bytes32 => VestingSchedule)
        private vestingScheduleForStakingAndReward;
    mapping(bytes32 => VestingSchedule) private vestingScheduleForAirOrBurn;
    mapping(bytes32 => VestingSchedule)
        private vestingScheduleForAdvisersAndPartnerships;

    //@notice keeping track of benificiries in diffrent roles
    mapping(address => bool) private companyReserveBeneficiaries;
    mapping(address => bool) private equityInvestorBeneficiaries;
    mapping(address => bool) private teamBeneficiaries;
    mapping(address => bool) private exchageListingAndLiquidityBeneficiaries;
    mapping(address => bool) private ecosystemBeneficiaries;
    mapping(address => bool) private stakingAndRewardBeneficiaries;
    mapping(address => bool) private airOrBurnBeneficiaries;
    mapping(address => bool) private advisersAndPartnershipsBeneficiaries;

    //@notice vesting schedule ID to track vesting
    bytes32[] private vestingSchedulesIds;

    enum Roles {
        CompanyReserve,
        EquityInvestor,
        Team,
        ExchageListingAndLiquidity,
        Ecosystem,
        StakingAndReward,
        AirOrBurn,
        AdvisersAndPartnerships
    }

    //@param for storing the token address for ERC20 token
    IERC20 private token;

    constructor(address _token) {
        require((_token != address(0)));
        token = IERC20(_token);
    }

    modifier onlyIfVestingScheduleExists(bytes32 vestingScheduleId, Roles r) {
        if (r == Roles.CompanyReserve) {
            require(
                vestingScheduleForCompanyReserve[vestingScheduleId]
                    .initialized == true
            );
        } else if (r == Roles.EquityInvestor) {
            require(
                vestingScheduleForEquityInvestor[vestingScheduleId]
                    .initialized == true
            );
        } else if (r == Roles.Team) {
            require(
                vestingScheduleForTeam[vestingScheduleId].initialized == true
            );
        } else if (r == Roles.ExchageListingAndLiquidity) {
            require(
                vestingScheduleForExchageListingAndLiquidity[vestingScheduleId]
                    .initialized == true
            );
        } else if (r == Roles.Ecosystem) {
            require(
                vestingScheduleForEcosystem[vestingScheduleId].initialized ==
                    true
            );
        } else if (r == Roles.StakingAndReward) {
            require(
                vestingScheduleForStakingAndReward[vestingScheduleId]
                    .initialized == true
            );
        } else if (r == Roles.AirOrBurn) {
            require(
                vestingScheduleForAirOrBurn[vestingScheduleId].initialized ==
                    true
            );
        } else if (r == Roles.AdvisersAndPartnerships) {
            require(
                vestingScheduleForAdvisersAndPartnerships[vestingScheduleId]
                    .initialized == true
            );
        }
        _;
    }

    modifier onlyIfVestingScheduleNotRevoked(
        bytes32 vestingScheduleId,
        Roles r
    ) {
        if (r == Roles.CompanyReserve) {
            require(
                vestingScheduleForCompanyReserve[vestingScheduleId]
                    .initialized == true
            );
            require(
                vestingScheduleForCompanyReserve[vestingScheduleId].revoked ==
                    false
            );
        } else if (r == Roles.EquityInvestor) {
            require(
                vestingScheduleForEquityInvestor[vestingScheduleId]
                    .initialized == true
            );
            require(
                vestingScheduleForEquityInvestor[vestingScheduleId].revoked ==
                    false
            );
        }
        if (r == Roles.Team) {
            require(
                vestingScheduleForTeam[vestingScheduleId].initialized == true
            );
            require(vestingScheduleForTeam[vestingScheduleId].revoked == false);
        }
        if (r == Roles.ExchageListingAndLiquidity) {
            require(
                vestingScheduleForExchageListingAndLiquidity[vestingScheduleId]
                    .initialized == true
            );
            require(
                vestingScheduleForExchageListingAndLiquidity[vestingScheduleId]
                    .revoked == false
            );
        }
        if (r == Roles.Ecosystem) {
            require(
                vestingScheduleForExchageListingAndLiquidity[vestingScheduleId]
                    .initialized == true
            );
            require(
                vestingScheduleForEcosystem[vestingScheduleId].revoked == false
            );
        }
        if (r == Roles.StakingAndReward) {
            require(
                vestingScheduleForStakingAndReward[vestingScheduleId].revoked ==
                    false
            );
        }
        if (r == Roles.AirOrBurn) {
            require(
                vestingScheduleForAirOrBurn[vestingScheduleId].initialized ==
                    true
            );
            require(
                vestingScheduleForAirOrBurn[vestingScheduleId].revoked == false
            );
        }
        if (r == Roles.AdvisersAndPartnerships) {
            require(
                vestingScheduleForAirOrBurn[vestingScheduleId].initialized ==
                    true
            );
            require(
                vestingScheduleForAdvisersAndPartnerships[vestingScheduleId]
                    .initialized == true
            );
            require(
                vestingScheduleForAdvisersAndPartnerships[vestingScheduleId]
                    .revoked == false
            );
        }
        _;
    }

    function getCurrentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function updateTotalSupply() internal onlyOwner {
        totalTokensInContract = token.balanceOf(address(this));
    }

    function addBeneficiary(address _address, Roles r) internal onlyOwner {
        if (r == Roles.CompanyReserve) {
            CompanyReserveBeneficiariesCount++;
            companyReserveBeneficiaries[_address] = true;
        } else if (r == Roles.EquityInvestor) {
            EquityInvestorBeneficiariesCount++;
            equityInvestorBeneficiaries[_address] = true;
        } else if (r == Roles.Team) {
            TeamBeneficiariesCount++;
            teamBeneficiaries[_address] = true;
        } else if (r == Roles.ExchageListingAndLiquidity) {
            ExchageListingAndLiquidityBeneficiariesCount++;
            exchageListingAndLiquidityBeneficiaries[_address] = true;
        } else if (r == Roles.Ecosystem) {
            EcosystemBeneficiariesCount++;
            ecosystemBeneficiaries[_address] = true;
        } else if (r == Roles.StakingAndReward) {
            StakingAndRewardBeneficiariesCount++;
            stakingAndRewardBeneficiaries[_address] = true;
        } else if (r == Roles.AirOrBurn) {
            AirOrBurnBeneficiariesCount++;
            airOrBurnBeneficiaries[_address] = true;
        } else if (r == Roles.AdvisersAndPartnerships) {
            AdvisersAndPartnershipsBeneficiariesCount++;
            advisersAndPartnershipsBeneficiaries[_address] = true;
        }
    }

    function conditionWhileCreatingSchedule(
        Roles r,
        address _beneficiary,
        uint256 _cliff,
        uint256 _start,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        bool _revocable,
        uint256 _amount,
        bytes32 vestingScheduleId
    ) internal {
        if (r == Roles.CompanyReserve) {
            uint256 _tgeAmount = 0;
            vestingScheduleForCompanyReserve[
                vestingScheduleId
            ] = VestingSchedule(
                true,
                _beneficiary,
                _cliff,
                _start,
                _duration,
                _slicePeriodSeconds,
                _revocable,
                _amount,
                0,
                _tgeAmount,
                false
            );
            vestingSchedulesTotalAmountForCompanyReserve = vestingSchedulesTotalAmountForCompanyReserve;
        }
        if (r == Roles.EquityInvestor) {
            uint256 _tgeAmount = (_amount * equityInvestorTGE) / 100;
            _amount = _amount - _tgeAmount;
            vestingScheduleForEquityInvestor[
                vestingScheduleId
            ] = VestingSchedule(
                true,
                _beneficiary,
                _cliff,
                _start,
                _duration,
                _slicePeriodSeconds,
                _revocable,
                _amount,
                0,
                _tgeAmount,
                false
            );

            vestingSchedulesTotalAmountForEquityInvestor = vestingSchedulesTotalAmountForEquityInvestor;
        }
        if (r == Roles.Team) {
            uint256 _tgeAmount = 0;
            vestingScheduleForTeam[vestingScheduleId] = VestingSchedule(
                true,
                _beneficiary,
                _cliff,
                _start,
                _duration,
                _slicePeriodSeconds,
                _revocable,
                _amount,
                0,
                _tgeAmount,
                false
            );
            vestingSchedulesTotalAmountForTeam = vestingSchedulesTotalAmountForTeam;
        }
        if (r == Roles.ExchageListingAndLiquidity) {
            uint256 _tgeAmount = (_amount * exchageListingAndLiquidityTGE) /
                100;
            _amount = _amount - _tgeAmount;
            vestingScheduleForExchageListingAndLiquidity[
                vestingScheduleId
            ] = VestingSchedule(
                true,
                _beneficiary,
                _cliff,
                _start,
                _duration,
                _slicePeriodSeconds,
                _revocable,
                _amount,
                0,
                _tgeAmount,
                false
            );
            vestingSchedulesTotalAmountForExchageListingAndLiquidity = vestingSchedulesTotalAmountForExchageListingAndLiquidity;
        }
        if (r == Roles.Ecosystem) {
            uint256 _tgeAmount = 0;
            vestingScheduleForEcosystem[vestingScheduleId] = VestingSchedule(
                true,
                _beneficiary,
                _cliff,
                _start,
                _duration,
                _slicePeriodSeconds,
                _revocable,
                _amount,
                0,
                _tgeAmount,
                false
            );
            vestingSchedulesTotalAmountForEcosystem = vestingSchedulesTotalAmountForEcosystem;
        }
        if (r == Roles.StakingAndReward) {
            uint256 _tgeAmount = (_amount * stakingAndRewardTGE) / 100;
            _amount = _amount - _tgeAmount;

            vestingScheduleForStakingAndReward[
                vestingScheduleId
            ] = VestingSchedule(
                true,
                _beneficiary,
                _cliff,
                _start,
                _duration,
                _slicePeriodSeconds,
                _revocable,
                _amount,
                0,
                _tgeAmount,
                false
            );

            vestingSchedulesTotalAmountForStakingAndReward = vestingSchedulesTotalAmountForStakingAndReward;
        }
        if (r == Roles.AirOrBurn) {
            uint256 _tgeAmount = (_amount * airOrBurnTGE) / 100;
            _amount = _amount - _tgeAmount;
            vestingScheduleForAirOrBurn[vestingScheduleId] = VestingSchedule(
                true,
                _beneficiary,
                _cliff,
                _start,
                _duration,
                _slicePeriodSeconds,
                _revocable,
                _amount,
                0,
                _tgeAmount,
                false
            );
            vestingSchedulesTotalAmountForAirOrBurn = vestingSchedulesTotalAmountForAirOrBurn;
        }
        if (r == Roles.AdvisersAndPartnerships) {
            uint256 _tgeAmount = 0;
            uint256 _extraTime = _slicePeriodSeconds / 4;
            uint256 _timeFrame = (_slicePeriodSeconds) + _extraTime;
            _duration = _timeFrame;
            vestingScheduleForAdvisersAndPartnerships[
                vestingScheduleId
            ] = VestingSchedule(
                true,
                _beneficiary,
                _cliff,
                _start,
                _duration,
                _slicePeriodSeconds,
                _revocable,
                _amount,
                0,
                _tgeAmount,
                false
            );
            vestingSchedulesTotalAmountForAdvisersAndPartnership = vestingSchedulesTotalAmountForAdvisersAndPartnership;
        }
    }

    function _computeReleasableAmount(
        VestingSchedule memory vestingSchedule,
        Roles r
    ) internal view returns (uint256) {
        uint256 currentTime = getCurrentTime();
        if (r == Roles.CompanyReserve) {
            if (
                (currentTime < vestingSchedule.cliff) ||
                vestingSchedule.revoked == true
            ) {
                return 0;
                // return vestingSchedule.tgeAmount;
            } else if (
                currentTime >= vestingSchedule.start + vestingSchedule.duration
            ) {
                return vestingSchedule.amountTotal - (vestingSchedule.released);
            } else {
                uint256 cliffTimeEnd = vestingSchedule.cliff;
                uint256 timeFromStart = currentTime - cliffTimeEnd;
                uint256 secondsPerSlice = vestingSchedule.slicePeriodSeconds;
                uint256 vestedSlicePeriods = timeFromStart / secondsPerSlice;
                uint256 vestedSeconds = vestedSlicePeriods * secondsPerSlice;
                uint256 vestedAmount = (vestingSchedule.amountTotal *
                    (vestedSeconds)) / vestingSchedule.duration;
                vestedAmount = vestedAmount - (vestingSchedule.released);
                return vestedAmount;
            }
        } else if (r == Roles.EquityInvestor) {
            if (vestingSchedule.revoked == true) {
                return 0;
            } else if (
                currentTime >= vestingSchedule.start + vestingSchedule.duration
            ) {
                return
                    (vestingSchedule.amountTotal +
                        (vestingSchedule.tgeAmount)) -
                    (vestingSchedule.released);
            } else {
                uint256 timeFromStart = currentTime - vestingSchedule.start;
                uint256 secondsPerSlice = vestingSchedule.slicePeriodSeconds;
                uint256 vestedSlicePeriods = timeFromStart / secondsPerSlice;
                uint256 vestedSeconds = vestedSlicePeriods * secondsPerSlice;
                // uint256 fivePercentValue  = (vestingSchedule.amountTotal * 5) / 100;
                uint256 vestedAmount = (vestingSchedule.amountTotal) +
                    (vestedSeconds) /
                    vestingSchedule.duration;
                return vestedAmount;
            }
        } else if (r == Roles.Team) {
            if (
                currentTime < vestingSchedule.cliff ||
                vestingSchedule.revoked == true
            ) {
                return 0;
            } else if (
                currentTime < vestingSchedule.start + vestingSchedule.duration
            ) {
                return vestingSchedule.amountTotal - (vestingSchedule.released);
            } else {
                uint256 cliffTimeEnd = vestingSchedule.cliff;
                uint256 timeFromStart = currentTime - (cliffTimeEnd);
                uint256 secondsPerSlice = vestingSchedule.slicePeriodSeconds;
                uint256 vestedSlicePeriods = timeFromStart / secondsPerSlice;
                uint256 vestedSeconds = vestedSlicePeriods * secondsPerSlice;
                uint256 vestedAmount = (vestingSchedule.amountTotal *
                    (vestedSeconds)) / vestingSchedule.duration;
                return vestedAmount;
            }
        } else if (r == Roles.ExchageListingAndLiquidity) {
            if (
                currentTime < vestingSchedule.cliff ||
                vestingSchedule.revoked == true
            ) {
                return 0;
            } else if (
                currentTime < vestingSchedule.start + vestingSchedule.duration
            ) {
                return
                    (vestingSchedule.amountTotal +
                        ((vestingSchedule.tgeAmount))) -
                    (vestingSchedule.released);
            } else {
                uint256 timeFromStart = currentTime - (vestingSchedule.start);
                uint256 secondsPerSlice = vestingSchedule.slicePeriodSeconds;
                uint256 vestedSlicePeriods = timeFromStart / secondsPerSlice;
                uint256 vestedSeconds = vestedSlicePeriods * secondsPerSlice;
                uint256 vestedAmount = (vestingSchedule.amountTotal *
                    (vestedSeconds)) / vestingSchedule.duration;
                return vestedAmount;
            }
        } else if (r == Roles.Ecosystem) {
            if (
                currentTime < vestingSchedule.cliff ||
                vestingSchedule.revoked == true
            ) {
                return 0;
            } else if (
                currentTime < vestingSchedule.start + vestingSchedule.duration
            ) {
                return vestingSchedule.amountTotal - (vestingSchedule.released);
            } else {
                uint256 timeFromStart = currentTime - (vestingSchedule.start);
                uint256 secondsPerSlice = vestingSchedule.slicePeriodSeconds;
                uint256 vestedSlicePeriods = timeFromStart / secondsPerSlice;
                uint256 vestedSeconds = vestedSlicePeriods * secondsPerSlice;
                uint256 vestedAmount = (vestingSchedule.amountTotal *
                    (vestedSeconds)) / vestingSchedule.duration;
                return vestedAmount;
            }
        } else if (r == Roles.StakingAndReward) {
            if (
                currentTime < vestingSchedule.cliff ||
                vestingSchedule.revoked == true
            ) {
                return 0;
            } else if (
                currentTime < vestingSchedule.start + vestingSchedule.duration
            ) {
                return
                    (vestingSchedule.amountTotal +
                        ((vestingSchedule.tgeAmount))) -
                    (vestingSchedule.released);
            } else {
                uint256 timeFromStart = currentTime - (vestingSchedule.start);
                uint256 secondsPerSlice = vestingSchedule.slicePeriodSeconds;
                uint256 vestedSlicePeriods = timeFromStart / secondsPerSlice;
                uint256 vestedSeconds = vestedSlicePeriods * secondsPerSlice;
                uint256 vestedAmount = (vestingSchedule.amountTotal *
                    (vestedSeconds)) / vestingSchedule.duration;
                return vestedAmount;
            }
        } else if (r == Roles.AirOrBurn) {
            if (
                currentTime < vestingSchedule.cliff ||
                vestingSchedule.revoked == true
            ) {
                return 0;
            } else if (
                currentTime < vestingSchedule.start + vestingSchedule.duration
            ) {
                return
                    (vestingSchedule.amountTotal +
                        ((vestingSchedule.tgeAmount))) -
                    (vestingSchedule.released);
            } else {
                uint256 timeFromStart = currentTime - (vestingSchedule.start);
                uint256 secondsPerSlice = vestingSchedule.slicePeriodSeconds;
                uint256 vestedSlicePeriods = timeFromStart / secondsPerSlice;
                uint256 vestedSeconds = vestedSlicePeriods * secondsPerSlice;
                uint256 vestedAmount = (vestingSchedule.amountTotal *
                    (vestedSeconds)) / vestingSchedule.duration;
                return vestedAmount;
            }
        }
        if (r == Roles.AdvisersAndPartnerships) {
            if (
                currentTime < vestingSchedule.cliff ||
                vestingSchedule.revoked == true
            ) {
                return 0;
            } else if (
                currentTime < vestingSchedule.start + vestingSchedule.duration
            ) {
                return vestingSchedule.amountTotal - (vestingSchedule.released);
            } else {
                uint256 timeFromStart = currentTime - (vestingSchedule.start);
                uint256 secondsPerSlice = vestingSchedule.slicePeriodSeconds;
                uint256 vestedSlicePeriods = timeFromStart / secondsPerSlice;
                uint256 vestedSeconds = vestedSlicePeriods * secondsPerSlice;
                uint256 vestedAmount = (vestingSchedule.amountTotal *
                    (vestedSeconds)) / vestingSchedule.duration;
                return vestedAmount;
            }
        }
    }

    function getVestingSchedulesCountByBeneficiary(address _beneficiary)
        external
        view
        returns (uint256)
    {
        return holdersVestingCount[_beneficiary];
    }

    function getVestingIdAtIndex(uint256 index)
        external
        view
        returns (bytes32)
    {
        require(
            index < getVestingSchedulesCount(),
            "TokenVesting: index out of bounds"
        );
        return vestingSchedulesIds[index];
    }

    function getVestingScheduleByAddressAndIndex(
        address holder,
        uint256 index,
        Roles r
    ) external view returns (VestingSchedule memory) {
        return
            getVestingSchedule(
                computeVestingScheduleIdForAddressAndIndex(holder, index),
                r
            );
    }

    function getVestingSchedulesTotalAmount(Roles r)
        external
        view
        returns (uint256)
    {
        if (r == Roles.CompanyReserve) {
            return vestingSchedulesTotalAmountForCompanyReserve;
        } else if (r == Roles.EquityInvestor) {
            return vestingSchedulesTotalAmountForEquityInvestor;
        } else if (r == Roles.Team) {
            return vestingSchedulesTotalAmountForTeam;
        } else if (r == Roles.ExchageListingAndLiquidity) {
            return vestingSchedulesTotalAmountForExchageListingAndLiquidity;
        } else if (r == Roles.Ecosystem) {
            return vestingSchedulesTotalAmountForEcosystem;
        } else if (r == Roles.StakingAndReward) {
            return vestingSchedulesTotalAmountForStakingAndReward;
        } else if (r == Roles.AirOrBurn) {
            return vestingSchedulesTotalAmountForAirOrBurn;
        } else if (r == Roles.AdvisersAndPartnerships) {
            return vestingSchedulesTotalAmountForAdvisersAndPartnership;
        }
    }

    function getToken() external view returns (address) {
        return address(token);
    }

    function createVestingSchedule(
        Roles r,
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _slicePeriodSeconds,
        bool _revocable,
        uint256 _amount
    ) external onlyOwner {
        require(
            this.getWithdrawableAmount() >= _amount,
            "TokenVesting: cannot create vesting schedule because not sufficient tokens"
        );
        uint256 cliff = _start + (_cliff);
        require(_duration > 0, "TokenVesting: duration must be > 0");
        require(_amount > 0, "TokenVesting: amount must be > 0");
        require(
            _slicePeriodSeconds >= 1,
            "TokenVesting: slicePeriodSeconds must be >= 1"
        );
        require(
            r == Roles.CompanyReserve ||
                r == Roles.EquityInvestor ||
                r == Roles.Team ||
                r == Roles.ExchageListingAndLiquidity ||
                r == Roles.Ecosystem ||
                r == Roles.StakingAndReward ||
                r == Roles.AirOrBurn ||
                r == Roles.AdvisersAndPartnerships,
            "TokenVesting: roles must be 1, 2, 3, 4, 5, 6, 7 or 8"
        );
        bytes32 vestingScheduleId = this.computeNextVestingScheduleIdForHolder(
            _beneficiary
        );
        conditionWhileCreatingSchedule(
            r,
            _beneficiary,
            cliff,
            _start,
            _duration,
            _slicePeriodSeconds,
            _revocable,
            _amount,
            vestingScheduleId
        );
        addBeneficiary(_beneficiary, r);
        vestingSchedulesIds.push(vestingScheduleId);
        uint256 currentVestingCount = holdersVestingCount[_beneficiary];
        holdersVestingCount[_beneficiary] = currentVestingCount + (1);
    }

    function getVestingSchedule(bytes32 vestingScheduleId, Roles r)
        public
        view
        returns (VestingSchedule memory)
    {
        if (r == Roles.CompanyReserve) {
            return vestingScheduleForCompanyReserve[vestingScheduleId];
        } else if (r == Roles.EquityInvestor) {
            return vestingScheduleForEquityInvestor[vestingScheduleId];
        } else if (r == Roles.Team) {
            return vestingScheduleForTeam[vestingScheduleId];
        } else if (r == Roles.ExchageListingAndLiquidity) {
            return
                vestingScheduleForExchageListingAndLiquidity[vestingScheduleId];
        } else if (r == Roles.Ecosystem) {
            return vestingScheduleForEcosystem[vestingScheduleId];
        } else if (r == Roles.StakingAndReward) {
            return vestingScheduleForStakingAndReward[vestingScheduleId];
        } else if (r == Roles.AirOrBurn) {
            return vestingScheduleForAirOrBurn[vestingScheduleId];
        } else if (r == Roles.AdvisersAndPartnerships) {
            return vestingScheduleForAdvisersAndPartnerships[vestingScheduleId];
        }
    }

    //@return to get the total withdrawable amount
    function getWithdrawableAmount() public view returns (uint256) {
        return totalWithdrawableAmount;
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

    function computeVestingScheduleIdForAddressAndIndex(
        address holder,
        uint256 index
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(holder, index));
    }

    function getVestingSchedulesCount() public view returns (uint256) {
        return vestingSchedulesIds.length;
    }

    function release(
        bytes32 vestingScheduleId,
        uint256 amount,
        Roles r
    ) public onlyIfVestingScheduleNotRevoked(vestingScheduleId, r) {
        VestingSchedule memory vestingSchedule;
        if (r == Roles.CompanyReserve) {
            vestingSchedule = vestingScheduleForCompanyReserve[
                vestingScheduleId
            ];
        } else if (r == Roles.EquityInvestor) {
            vestingSchedule = vestingScheduleForEquityInvestor[
                vestingScheduleId
            ];
        } else if (r == Roles.Team) {
            vestingSchedule = vestingScheduleForTeam[vestingScheduleId];
        } else if (r == Roles.ExchageListingAndLiquidity) {
            vestingSchedule = vestingScheduleForExchageListingAndLiquidity[
                vestingScheduleId
            ];
        } else if (r == Roles.Ecosystem) {
            vestingSchedule = vestingScheduleForEcosystem[vestingScheduleId];
        } else if (r == Roles.StakingAndReward) {
            vestingSchedule = vestingScheduleForStakingAndReward[
                vestingScheduleId
            ];
        } else if (r == Roles.AirOrBurn) {
            vestingSchedule = vestingScheduleForAirOrBurn[vestingScheduleId];
        } else if (r == Roles.AdvisersAndPartnerships) {
            vestingSchedule = vestingScheduleForAdvisersAndPartnerships[
                vestingScheduleId
            ];
        }
        bool isBeneficiary = msg.sender == vestingSchedule.beneficiary;
        uint256 currentTime = getCurrentTime();
        bool isOwner = msg.sender == owner();
        require(
            isBeneficiary || isOwner,
            "TokenVesting: only beneficiary or owner can release tokens"
        );
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule, r);
        require(
            vestedAmount >= amount,
            "TokenVesting: cannot release tokens, not enough vested tokens"
        );
        vestingSchedule.released = vestingSchedule.released + (amount);
        address payable beneficiaryPayable = payable(
            vestingSchedule.beneficiary
        );
        if (r == Roles.CompanyReserve) {
            vestingSchedulesTotalAmountForCompanyReserve = (vestingSchedulesTotalAmountForCompanyReserve -
                (amount));
        } else if (r == Roles.EquityInvestor) {
            vestingSchedulesTotalAmountForEquityInvestor = (vestingSchedulesTotalAmountForEquityInvestor -
                (amount));
        } else if (r == Roles.Team) {
            vestingSchedulesTotalAmountForTeam = (vestingSchedulesTotalAmountForTeam -
                (amount));
        } else if (r == Roles.ExchageListingAndLiquidity) {
            vestingSchedulesTotalAmountForExchageListingAndLiquidity = (vestingSchedulesTotalAmountForExchageListingAndLiquidity -
                (amount));
        } else if (r == Roles.Ecosystem) {
            vestingSchedulesTotalAmountForEcosystem = (vestingSchedulesTotalAmountForEcosystem -
                (amount));
        } else if (r == Roles.StakingAndReward) {
            vestingSchedulesTotalAmountForStakingAndReward = (vestingSchedulesTotalAmountForStakingAndReward -
                (amount));
        } else if (r == Roles.AirOrBurn) {
            vestingSchedulesTotalAmountForAirOrBurn = (vestingSchedulesTotalAmountForAirOrBurn -
                (amount));
        } else if (r == Roles.AdvisersAndPartnerships) {
            vestingSchedulesTotalAmountForAdvisersAndPartnership = (vestingSchedulesTotalAmountForAdvisersAndPartnership -
                (amount));
        }
        token.safeTransfer(beneficiaryPayable, amount);
    }

    function setTGE(
        uint256 _TGEForCompanyReserve,
        uint256 _TGEForEquityInvestor,
        uint256 _TGEForTeam,
        uint256 _TGEForExchageListingAndLiquidity,
        uint256 _TGEForEcosystem,
        uint256 _TGEForStakingAndReward,
        uint256 _TGEForAirOrBurn,
        uint256 _TGEForAdvisersAndPartnerships
    ) external onlyOwner {
        companyReserveTGE = _TGEForCompanyReserve;
        equityInvestorTGE = _TGEForEquityInvestor;
        teamTGE = _TGEForTeam;
        exchageListingAndLiquidityTGE = _TGEForExchageListingAndLiquidity;
        ecosystemTGE = _TGEForEcosystem;
        stakingAndRewardTGE = _TGEForStakingAndReward;
        airOrBurnTGE = _TGEForAirOrBurn;
        advisersAndPartnershipsTGE = _TGEForAdvisersAndPartnerships;
    }

    function calculatePools() public onlyOwner {
        updateTotalSupply();
        vestingSchedulesTotalAmountForCompanyReserve =
            (totalTokensInContract * (15)) /
            (100);
        vestingSchedulesTotalAmountForEquityInvestor =
            (totalTokensInContract * (3)) /
            (100);
        vestingSchedulesTotalAmountForTeam =
            (totalTokensInContract * (10)) /
            (100);
        vestingSchedulesTotalAmountForExchageListingAndLiquidity =
            (totalTokensInContract * (25)) /
            (100);
        vestingSchedulesTotalAmountForEcosystem =
            (totalTokensInContract * (10)) /
            (100);
        vestingSchedulesTotalAmountForStakingAndReward =
            (totalTokensInContract * (15)) /
            (100);
        vestingSchedulesTotalAmountForAirOrBurn =
            (totalTokensInContract * (2)) /
            (100);
        vestingSchedulesTotalAmountForAdvisersAndPartnership =
            (totalTokensInContract * (10)) /
            (100);

        companyReserveTGEPool =
            (vestingSchedulesTotalAmountForCompanyReserve *
                (companyReserveTGE)) /
            (100);
        equityInvestorTGEPool =
            (vestingSchedulesTotalAmountForEquityInvestor *
                (equityInvestorTGE)) /
            (100);
        teamTGEPool = (vestingSchedulesTotalAmountForTeam * (teamTGE)) / (100);
        exchageListingAndLiquidityTGEPool =
            (vestingSchedulesTotalAmountForExchageListingAndLiquidity *
                (exchageListingAndLiquidityTGE)) /
            (100);
        ecosystemTGEPool =
            (vestingSchedulesTotalAmountForEcosystem * (ecosystemTGE)) /
            (100);
        stakingAndRewardTGEPool =
            (vestingSchedulesTotalAmountForStakingAndReward *
                (stakingAndRewardTGE)) /
            (100);
        airOrBurnTGEPool =
            (vestingSchedulesTotalAmountForAirOrBurn * (airOrBurnTGE)) /
            (100);
        advisersAndPartnershipsTGEPool =
            (vestingSchedulesTotalAmountForAdvisersAndPartnership *
                (advisersAndPartnershipsTGE)) /
            (100);

        companyReserveVestingPool =
            vestingSchedulesTotalAmountForCompanyReserve -
            companyReserveTGEPool;
        equityInvestorVestingPool =
            vestingSchedulesTotalAmountForEquityInvestor -
            equityInvestorTGEPool;
        teamVestingPool = vestingSchedulesTotalAmountForTeam - teamTGEPool;
        exchageListingAndLiquidityVestingPool =
            vestingSchedulesTotalAmountForExchageListingAndLiquidity -
            exchageListingAndLiquidityTGEPool;
        ecosystemVestingPool =
            vestingSchedulesTotalAmountForEcosystem -
            ecosystemTGEPool;
        stakingAndRewardVestingPool =
            vestingSchedulesTotalAmountForStakingAndReward -
            stakingAndRewardTGEPool;
        airOrBurnVestingPool =
            vestingSchedulesTotalAmountForAirOrBurn -
            airOrBurnTGEPool;
        advisersAndPartnershipsVestingPool =
            vestingSchedulesTotalAmountForAdvisersAndPartnership -
            advisersAndPartnershipsTGEPool;

        updateTotalWithdrawableAmount();
    }

    function updateTotalWithdrawableAmount() internal onlyOwner {
        uint256 reservedAmount = vestingSchedulesTotalAmountForCompanyReserve +
            vestingSchedulesTotalAmountForEquityInvestor +
            vestingSchedulesTotalAmountForTeam +
            vestingSchedulesTotalAmountForExchageListingAndLiquidity +
            vestingSchedulesTotalAmountForEcosystem +
            vestingSchedulesTotalAmountForStakingAndReward +
            vestingSchedulesTotalAmountForAirOrBurn +
            vestingSchedulesTotalAmountForAdvisersAndPartnership;
        totalWithdrawableAmount =
            token.balanceOf(address(this)) -
            reservedAmount;
    }
}
