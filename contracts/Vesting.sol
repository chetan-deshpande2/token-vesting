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

    //@notice to set TEG for advisors and partners and mentors TEG
    uint256 public advisorsTGE;
    uint256 public partnersTGE;
    uint256 public mentorsTGE;

    //@notice variables to keep count of total tokens in the contract
    uint256 public totalTokenInContract;
    uint256 public totalWithdrawableAmount;

    //@notice tokens that can be withdrawn any time
    uint256 public advisersTGEPool;
    uint256 public partnersTGEPool;
    uint256 public mentorsTGEPool;

    // @notice tracking beneficiary count
    uint256 public advisersBeneficiariesCount = 0;
    uint256 public partnersBeneficiariesCount = 0;
    uint256 public mentorsBeneficiariesCount = 0;

    //@notice tokens that can be vested .
    uint256 public vestingPoolForAdvisors;
    uint256 public vestingPoolForPartners;
    uint256 public vestingPoolForMentors;

    //@notice total Token each division has for vesting
    uint256 public vestingSchedulesTotalAmountforAdvisors;
    uint256 public vestingSchedulesTotalAmountforPartners;
    uint256 public vestingSchedulesTotalAmountforMentors;

    //tracking TGE pool
    uint256 public advisersTGEBank;
    uint256 public partnersTGEBank;
    uint256 public mentorsTGEBank;

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
    @notice  Events for relased , revoke and createScheudle functions
    @param vestingScheduleId  to know the vesting schedule details that were created
    @param role to know the role of the vesting schedule that is created;

    */

    event Released(
        bytes32 vestingScheduleId,
        Roles role,
        address beneficiary,
        uint256 amount
    );

    event Revoked(bytes32 vestingScheduleId, Roles role);
    event Schedule(
        Roles role,
        address beneficiary,
        uint256 start,
        uint256 cliff,
        uint256 duration,
        uint256 slicePeriodSeconds,
        bool revocable,
        uint256 amount
    );

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
    function getCurrentTime() public view virtual returns (uint256) {
        return block.timestamp;
    }

    function updateTotalSupply() internal onlyOwner {
        totalTokenInContract = token.balanceOf(address(this));
    }

    function updateTotalWithdrawableAmount() internal onlyOwner {
        totalWithdrawableAmount =
            token.balanceOf(address(this)) ;
    }

    /*
   @notice update the benificiary count
   @param _address that is address of the benificiary
   @param role  the role of the benificiaries
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
                false
            );
            vestingSchedulesTotalAmountforAdvisors = totalTokenInContract;
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
                false
            );
            vestingSchedulesTotalAmountforPartners = totalTokenInContract;
        } else {
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
                false
            );
            vestingSchedulesTotalAmountforMentors = totalTokenInContract;
        }
    }

    /*
    @notice calculating the total release amount
     @param vestingSchedule is to send in the details of the vesting schedule created
     @return the calculated releaseable amount depending on the role
     */
    function _computeReleasableAmount(VestingSchedule memory vestingSchedule)
        internal
        view
        returns (uint256)
    {
        uint256 currentTime = getCurrentTime();
        if (
            currentTime < vestingSchedule.cliff ||
            vestingSchedule.revoked == true
        ) {
            return 0;
        } else if (
            currentTime >= vestingSchedule.start + (vestingSchedule.duration)
        ) {
            return vestingSchedule.amountTotal - (vestingSchedule.released);
        } else {
            uint256 timeFromStart = currentTime - (vestingSchedule.start);
            uint256 secondsPerSlice = vestingSchedule.slicePeriodSeconds;
            uint256 vestedSlicePeriods = timeFromStart / (secondsPerSlice);
            uint256 vestedSeconds = vestedSlicePeriods * (secondsPerSlice);
            uint256 vestedAmount = (vestingSchedule.amountTotal *
                (vestedSeconds)) / (vestingSchedule.duration);
            vestedAmount = vestedAmount - (vestingSchedule.released);
            return vestedAmount;
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
        return vestingScheduleIds[index];
    }

    function getVestingScheduleByAddressAndIndex(
        address holder,
        uint256 index,
        Roles role
    ) external view returns (VestingSchedule memory) {
        return
            getVestingSchedule(
                computeVestingScheduleIdForAddressAndIndex(holder, index),
                role
            );
    }

    function getVestingSchedule(bytes32 vestingScheduleId, Roles role)
        public
        view
        returns (VestingSchedule memory)
    {
        if (role == Roles.Advisors) {
            return vestingScheduleForAdvisors[vestingScheduleId];
        } else if (role == Roles.Partners) {
            return vestingScheduleForPartners[vestingScheduleId];
        } else {
            return vestingScheduleForMentors[vestingScheduleId];
        }
    }

    // function getVestingSchedulesTotalAmount(Roles role)
    //     public
    //     view
    //     returns (uint256)
    // {
    //     if (role == Roles.Advisors) {
    //         return vestingSchedulesTotalAmountforAdvisors;
    //     } else if (role == Roles.Partners) {
    //         return vestingSchedulesTotalAmountforPartners;
    //     } else {
    //         return vestingSchedulesTotalAmountforMentors;
    //     }
    // }

    function getToken() external view returns (address) {
        return address(token);
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
            "Token vesting : roles must be 0 ,1 or 2"
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
        holdersVestingCount[_beneficiary] +=  1;
        emit Schedule(
            role,
            _beneficiary,
            _start,
            _cliff,
            _duration,
            _slicePeriodSeconds,
            _revocable,
            _amount
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

            uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);

            if (vestedAmount > 0) {
                release(vestingScheduleId, vestedAmount, role);
            }
            uint256 unreleased = vestingSchedule.amountTotal -
                (vestingSchedule.released);

            vestingSchedulesTotalAmountforAdvisors =
                totalTokenInContract -
                unreleased;
            vestingSchedule.revoked = true;
        } else if (role == Roles.Partners) {
            VestingSchedule
                storage vestingSchedule = vestingScheduleForPartners[
                    vestingScheduleId
                ];
            require(
                vestingSchedule.revocable == true,
                "Token Vesting : vesting is not revokable"
            );
            uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
            if (vestedAmount > 0) {
                release(vestingScheduleId, vestedAmount, role);
            }
            uint256 unreleased = vestingSchedule.amountTotal -
                (vestingSchedule.released);

            vestingSchedulesTotalAmountforPartners =
                totalTokenInContract -
                unreleased;
            vestingSchedule.revoked = true;
        }
        if (role == Roles.Mentors) {
            VestingSchedule storage vestingSchedule = vestingScheduleForMentors[
                vestingScheduleId
            ];
            require(
                vestingSchedule.revocable == true,
                "Token Vesting : vesting is not revokable"
            );
            uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
            if (vestedAmount > 0) {
                release(vestingScheduleId, vestedAmount, role);
            }
            uint256 unreleased = vestingSchedule.amountTotal -
                (vestingSchedule.released);

            vestingSchedulesTotalAmountforAdvisors =
                totalTokenInContract -
                unreleased;
            vestingSchedule.revoked = true;
        }

        emit Revoked(vestingScheduleId, role);
    }

    function withdraw(uint256 amount) public onlyOwner {
        require(
            this.getWithdrawableAmount() >= amount,
            "TokenVesting: not enough withdrawable funds"
        );
        totalWithdrawableAmount = totalWithdrawableAmount - (amount);
        token.safeTransfer(owner(), amount);
    }

    /*
     @param vestingScheduleId is used to get the details of the created vesting scheduel
     @param amount is used to get the total amount to be released
     @param role is used to know the role
    */
    function release(
        bytes32 vestingScheduleId,
        uint256 amount,
        Roles role
    ) public onlyIfVestingScheduleNotRevoked(vestingScheduleId, role) {
        VestingSchedule memory vestingSchedule;
        if (role == Roles.Advisors) {
            vestingSchedule = vestingScheduleForAdvisors[vestingScheduleId];
        } else if (role == Roles.Partners) {
            vestingSchedule = vestingScheduleForPartners[vestingScheduleId];
        } else if (role == Roles.Mentors) {
            vestingSchedule = vestingScheduleForMentors[vestingScheduleId];
        }

        bool isBeneficiary = msg.sender == vestingSchedule.beneficiary;

        bool isOwner = msg.sender == owner();
        require(
            isBeneficiary || isOwner,
            "Token Vesting: only beneficiary and owner can release vested tokens"
        );

        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        require(
            vestedAmount >= amount,
            "Token Vesting: cannot release tokens, not enough vested tokens"
        );
        vestingSchedule.released = vestingSchedule.released + (amount);
        address payable beneficiary = payable(vestingSchedule.beneficiary);
        if (role == Roles.Advisors) {
            vestingSchedulesTotalAmountforAdvisors =
                totalTokenInContract -
                amount;
        } else if (role == Roles.Partners) {
            vestingSchedulesTotalAmountforPartners =
                totalTokenInContract -
                amount;
        }
        if (role == Roles.Mentors) {
            vestingSchedulesTotalAmountforMentors =
                totalTokenInContract -
                amount;
        }

        token.safeTransfer(beneficiary, amount);
        emit Released(vestingScheduleId, role, beneficiary, amount);
    }

    //@return vesting ScheduleCount
    function getVestingSchedulesCount() public view returns (uint256) {
        return vestingScheduleIds.length;
    }

    function computeReleasableAmount(bytes32 vestingScheduleId, Roles role)
        public
        view
        onlyIfVestingScheduleNotRevoked(vestingScheduleId, role)
        returns (uint256)
    {
        VestingSchedule storage vestingSchedule;
        if (role == Roles.Advisors) {
            vestingSchedule = vestingScheduleForAdvisors[vestingScheduleId];
        } else if (role == Roles.Partners) {
            vestingSchedule = vestingScheduleForPartners[vestingScheduleId];
        } else {
            vestingSchedule = vestingScheduleForMentors[vestingScheduleId];
        }
        return _computeReleasableAmount(vestingSchedule);
    }

    //@return to get the total withdrawable amount
    function getWithdrawableAmount() public view returns (uint256) {
        return totalWithdrawableAmount;
    }

    /**
     * @dev Returns the last vesting schedule for a given holder address.
     */
    function getLastVestingScheduleForHolder(address holder, Roles role)
        public
        view
        returns (VestingSchedule memory)
    {
        if (role == Roles.Advisors) {
            return
                vestingScheduleForAdvisors[
                    computeVestingScheduleIdForAddressAndIndex(
                        holder,
                        holdersVestingCount[holder] - 1
                    )
                ];
        } else if (role == Roles.Partners) {
            return
                vestingScheduleForPartners[
                    computeVestingScheduleIdForAddressAndIndex(
                        holder,
                        holdersVestingCount[holder] - 1
                    )
                ];
        } else {
            return
                vestingScheduleForMentors[
                    computeVestingScheduleIdForAddressAndIndex(
                        holder,
                        holdersVestingCount[holder] - 1
                    )
                ];
        }
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

    function withdrawFromTGEBank(Roles role, uint256 _amount) public {
        bool isOwner = msg.sender == owner();
        if (role == Roles.Advisors) {
            require(
                advisorsBenificiaries[msg.sender] == true || isOwner,
                "You're not a beneficiary"
            );
            require(
                _amount <= advisersTGEBank / (advisersBeneficiariesCount),
                "you can not withdraw"
            );
            advisersTGEBank = advisersTGEBank - _amount;
            token.safeTransfer(msg.sender, _amount);
        } else if (role == Roles.Partners) {
            require(
                partnersBeneficiaries[msg.sender] == true || isOwner,
                "You're not a beneficiary"
            );
            require(
                _amount <= partnersTGEBank / (partnersBeneficiariesCount),
                "you can not withdraw"
            );
            partnersTGEBank = advisersTGEBank - _amount;
            token.safeTransfer(msg.sender, _amount);
        } else if (role == Roles.Mentors) {
            require(
                mentorsBeneficiaries[msg.sender] == true || isOwner,
                "You're not a beneficiary"
            );
            require(
                _amount <= mentorsTGEBank / (mentorsBeneficiariesCount),
                "you can not withdraw"
            );
            mentorsTGEBank = advisersTGEBank - _amount;
            token.safeTransfer(msg.sender, _amount);
        }
    }

    function setTGE(
        uint256 _TGEForAdvisors,
        uint256 _TGEForPartners,
        uint256 _TGEForMentors
    ) public onlyOwner {
        advisorsTGE = _TGEForAdvisors;
        partnersTGE = _TGEForPartners;
        mentorsTGE = _TGEForMentors;
    }

    // @notice updates the pool and total amount for each role
    /// @dev this function is to be called once the TGE is set and the contract is deployed
    function calculatePools() public onlyOwner {
        updateTotalSupply();
        // vestingSchedulesTotalAmountforAdvisors =
        //     (totalTokenInContract * (20)) /
        //     (100);
        // vestingSchedulesTotalAmountforPartners =
        //     (totalTokenInContract * (20)) /
        //     (10) /
        //     (100);
        // vestingSchedulesTotalAmountforMentors =
        //     (totalTokenInContract * (30)) /
        //     (100);

        vestingPoolForAdvisors =
            (totalTokenInContract * (advisorsTGE)) /
            (100);
        vestingPoolForPartners =
            (totalTokenInContract * (partnersTGE)) /
            (100);
        vestingPoolForMentors =
            (totalTokenInContract * (mentorsTGE)) /
            (100);

        advisersTGEBank = vestingPoolForAdvisors;
        partnersTGEBank = vestingPoolForPartners;
        mentorsTGEBank = vestingPoolForMentors;

        vestingPoolForAdvisors =
            vestingSchedulesTotalAmountforAdvisors -
            advisersTGEPool;
        vestingPoolForPartners =
            vestingSchedulesTotalAmountforPartners -
            partnersTGEPool;
        vestingPoolForMentors =
            vestingSchedulesTotalAmountforMentors -
            mentorsTGEPool;
    }
}
