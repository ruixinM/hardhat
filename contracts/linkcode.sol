// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title RecruitCoin
 */
contract RecruitCoinTest is ERC20, Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IERC20[] public paymentTokens;
  uint256[8] public supplies = [
    250_000_000, // TOTAL_SUPPLY
    250_000, // SOFT_CAP
    125_000_0, // HARD_CAP
    125_000_00, // 5% PUBLIC_SALE
    250_000_00, // 10% PRE_SALE
    625_000_00, // 25% EARLY
    150_000_000, // 60% PUBLIC_UNCAPPED
    0 // total payment is dollar (stable coin) raised.
  ];
  uint256[2] public prices = [0.11 ether, 0.021 ether];
  uint256[4] public dates = [
    getCurrentTime(), // preSaleStart
    getCurrentTime().add(30 days), // preSaleEnd
    getCurrentTime().add(30 days), // publicSaleStart
    getCurrentTime().add(60 days) // publicSaleEnd
  ];
  uint256[4] public bonus = [
    15, // week 1
    10, // week 2
    7, // week 3
    5 // week 4
  ];

  uint256 private constant MONTH_TIME = 30 days;
  uint256 private constant YEAR_TIME = 365 days;
  uint256 private constant THREE_MONTH = 90 days;
  uint256 private constant SIX_MONTH = 180 days;

  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  struct VestingSchedule {
    bool initialized;
    // beneficiary of tokens after they are released
    address beneficiary;
    // cliff period in seconds
    uint256 cliff;
    // start time of the vesting period
    uint256 start;
    // duration of the vesting period in seconds
    uint256 duration;
    // duration of a slice period for the vesting in seconds
    uint256 slicePeriodSeconds;
    // whether or not the vesting is revocable
    bool revocable;
    // total amount of tokens to be released at the end of the vesting
    uint256 amountTotal;
    // amount of tokens released
    uint256 released;
    // whether or not the vesting has been revoked
    bool revoked;
  }

  bytes32[] private vestingSchedulesIds;
  mapping(bytes32 => VestingSchedule) private vestingSchedules;
  uint256 private vestingSchedulesTotalAmount;
  mapping(address => uint256) private holdersVestingCount;

  event Deposits(address depositor, uint256 paymentAmount, uint256 purchasedTokens);
  event Claimed(uint256 amount);

  /**
   * @dev Reverts if no vesting schedule matches the passed identifier.
   */
  modifier onlyIfVestingScheduleExists(bytes32 vestingScheduleId) {
    require(vestingSchedules[vestingScheduleId].initialized == true, "No Vesting found");
    _;
  }

  /**
   * @dev Reverts if the vesting schedule does not exist or has been revoked.
   */
  modifier onlyIfVestingScheduleNotRevoked(bytes32 vestingScheduleId) {
    require(vestingSchedules[vestingScheduleId].initialized == true, "No Vesting found");
    require(vestingSchedules[vestingScheduleId].revoked == false, "Revoke not allowed");
    _;
  }

  constructor() ERC20("Recruit Coin", "RECUT") {
    paymentTokens = [
      IERC20(0x534399090DA190a2e1Cf868299A448907f1b2a27), // DAI
      IERC20(0xA11c8D9DC9b66E209Ef60F0C8D969D3CD988782c), // USDT
      IERC20(0x8301F2213c0eeD49a7E28Ae4c3e91722919B8B47), // BUSD
      IERC20(0xF976a4dc07201F4e0F9FC8f85766344D7a93c456) // TUSD
    ];
  }

  /*
   * @dev deposit function use to get deposits from user's
   * @param paymentAmount : amount paying to get tokens on claim
   */
  function deposit(uint256 paymentAmount, uint8 pTIndex) public {
    _deposit(msg.sender, paymentAmount, pTIndex);
  }

  function _deposit(
    address depositor,
    uint256 paymentAmount,
    uint8 pTIndex
  ) private {
    uint256 purchasedTokens = 0;

    /*PRE SALE*/
    if (getCurrentTime() >= dates[0] && getCurrentTime() < dates[1]) {
      purchasedTokens = paymentAmount.div(prices[0]);
      require(supplies[4] >= purchasedTokens, "OVERFLOW PURCHASE");
      supplies[4] = supplies[4].sub(purchasedTokens);
      supplies[7] = supplies[7].add(purchasedTokens);
      uint256 timeToLock = getCurrentTime().add(YEAR_TIME);
      _createVestingSchedule(depositor, timeToLock, MONTH_TIME, YEAR_TIME, 1, false, purchasedTokens);
    }
    /*PUBLIC SALE*/
    else if (getCurrentTime() >= dates[2] && getCurrentTime() < dates[3]) {
      purchasedTokens = paymentAmount.div(prices[0]);
      uint256 purchasedTokensBonus = purchasedTokens.mul(bonus[getBonusWeek().sub(1)]).div(100);
      require(supplies[3] >= purchasedTokens.add(purchasedTokensBonus), "OVERFLOW PURCHASE");
      supplies[3] = supplies[3].sub(purchasedTokens);
      supplies[7] = supplies[7].add(purchasedTokens);

      uint256 timeToLock = getCurrentTime().add(SIX_MONTH);
      if (getBonusWeek() <= 2) {
        timeToLock = getCurrentTime().add(THREE_MONTH);
      }

      _createVestingSchedule(depositor, timeToLock, MONTH_TIME, YEAR_TIME, 1, false, purchasedTokens);
    } else {
      revert("SALE IS NOT AVALIBLE");
    }

    paymentTokens[pTIndex].transferFrom(depositor, address(this), paymentAmount);

    emit Deposits(depositor, paymentAmount, purchasedTokens);
  }

  /**
   * @notice Creates a new vesting schedule for a beneficiary.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _start start time of the vesting period
   * @param _cliff duration in seconds of the cliff in which tokens will begin to vest
   * @param _duration duration in seconds of the period in which the tokens will vest
   * @param _slicePeriodSeconds duration of a slice period for the vesting in seconds
   * @param _revocable whether the vesting is revocable or not
   * @param _amount total amount of tokens to be released at the end of the vesting
   */
  function _createVestingSchedule(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    uint256 _slicePeriodSeconds,
    bool _revocable,
    uint256 _amount
  ) private {
    require(_duration > 0, "duration > 0");
    require(_amount > 0, "amount > 0");
    require(_slicePeriodSeconds >= 1, "SlicePeriodSeconds >= 1");
    bytes32 vestingScheduleId = this.computeNextVestingScheduleIdForHolder(_beneficiary);
    uint256 cliff = _start.add(_cliff);
    vestingSchedules[vestingScheduleId] = VestingSchedule(
      true,
      _beneficiary,
      cliff,
      _start,
      _duration,
      _slicePeriodSeconds,
      _revocable,
      _amount,
      0,
      false
    );
    vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.add(_amount);
    vestingSchedulesIds.push(vestingScheduleId);
    uint256 currentVestingCount = holdersVestingCount[_beneficiary];
    holdersVestingCount[_beneficiary] = currentVestingCount.add(1);
  }

  /**
   * @notice Revokes the vesting schedule for given identifier.
   * @param vestingScheduleId the vesting schedule identifier
   */
  function revoke(bytes32 vestingScheduleId) public onlyOwner onlyIfVestingScheduleNotRevoked(vestingScheduleId) {
    VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
    require(vestingSchedule.revocable == true, "vesting is not revocable");
    uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
    if (vestedAmount > 0) {
      claim(vestingScheduleId, vestedAmount);
    }
    uint256 unreleased = vestingSchedule.amountTotal.sub(vestingSchedule.released);
    vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.sub(unreleased);
    vestingSchedule.revoked = true;
  }

  /**
   * @notice claim vested amount of tokens.
   * @param vestingScheduleId the vesting schedule identifier
   * @param amount the amount to release
   */
  function claim(bytes32 vestingScheduleId, uint256 amount) public nonReentrant onlyIfVestingScheduleNotRevoked(vestingScheduleId) {
    VestingSchedule storage vestingSchedule = vestingSchedules[vestingScheduleId];
    bool isBeneficiary = msg.sender == vestingSchedule.beneficiary;
    bool isOwner = msg.sender == owner();
    require(isBeneficiary || isOwner, "Only beneficiary can claim");
    uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
    require(vestedAmount >= amount, "Tokens not avalible");
    vestingSchedule.released = vestingSchedule.released.add(amount);
    address payable beneficiaryPayable = payable(vestingSchedule.beneficiary);
    vestingSchedulesTotalAmount = vestingSchedulesTotalAmount.sub(amount);
    _mint(beneficiaryPayable, amount);
  }

  /*
   * @dev earlyMint function use to mint tokens to any wallet address
   * @param _recipients : address's array to mint tokens
   * @param _amount : amount to mint the tokens
   */
  function earlyMint(address[] calldata _recipients, uint256[] calldata _amount) public onlyOwner {
    for (uint256 i = 0; i < _recipients.length; i++) {
      require(_amount[i] <= supplies[5], "OVERFLOW ALLOCATION");
      require(_recipients[i] != address(0), "ADDRESS REQUIRED");
      require(_amount[i] <= 0, "AMOUNT REQUIRED");
      supplies[5] = supplies[5].sub(_amount[i]);
      _mint(_recipients[i], _amount[i]);
    }
  }

  /*
   * @dev mint function use to mint tokens to any wallet address
   * @param _recipients : address's array to mint tokens
   * @param _amount : amount to mint the tokens
   */
  function mint(address[] calldata _recipients, uint256[] calldata _amount) public onlyOwner {
    for (uint256 i = 0; i < _recipients.length; i++) {
      require(_recipients[i] != address(0), "ADDRESS REQUIRED");
      require(_amount[i] <= 0, "AMOUNT REQUIRED");
      supplies[6] = supplies[6].sub(_amount[i]);
      _mint(_recipients[i], _amount[i]);
    }
  }

  /*
   * @dev setBonus function use to update the bonus for public sale
   * @param _bonus : 4 bonus percentage based on 4 weeks
   */
  function setBonus(uint256[4] calldata _bonus) public onlyOwner {
    bonus = _bonus;
  }

  /*
   * @dev setDates function use to update the dates for sale
   * @param _dates : 4 dates , presale start and end, publicsale start and end
   */
  function setDates(uint256[4] calldata _dates) public onlyOwner {
    dates = _dates;
  }

  /*
   * @dev setPaymentTokens function use to update the payment tokens
   * @param _paymentTokens : address's for payment tokens
   */
  function setPaymentTokens(IERC20[] calldata _paymentTokens) public onlyOwner {
    paymentTokens = _paymentTokens;
  }

  /*
   * @dev setPrices function use to update the prices
   * @param _prices : [0:preSale,1:publicSale]
   */
  function setPrices(uint256[2] calldata _prices) public onlyOwner {
    prices = _prices;
  }

  /*
   * @dev getCurrentTime function returns the current block.timestamp
   */
  function getCurrentTime() internal view returns (uint256) {
    return block.timestamp;
  }

  /*
   * @dev getMonth function returns the month in timestamp
   */
  function getMonth() internal pure returns (uint256) {
    return (30 days);
  }

  /*
   * @dev getWeek function returns the week in timestamp
   */
  function getWeek() internal pure returns (uint256) {
    return (1 * 7 * 24 * 60 * 60);
  }

  /*
   * @dev getBonusWeek function returns the number of week in public sale
   */
  function getBonusWeek() internal view returns (uint256) {
    return getCurrentTime().sub(dates[2]).div(getWeek()).add(1);
  }

  /*
   * @dev getLockMonth function returns the number of months to lock the tokens
   */
  function getLockMonth() internal view returns (uint8) {
    uint8 lockMonth = 6;
    if (getBonusWeek() <= 2) {
      lockMonth = 3;
    }
    return lockMonth;
  }

  /*
   * @dev getLockTime function returns the number of months to lock the tokens
   */
  function getLockTime() internal view returns (uint256) {
    return getCurrentTime().add(getMonth().add(getLockMonth()));
  }

  /*
   * @dev withdrawTokens function withdraws the tokens from the contract to wallet
   */
  function withdrawTokens(uint8 pTIndex, uint256 amount) public onlyOwner {
    require(paymentTokens[pTIndex].balanceOf(address(this)) >= amount, "INSUFFICIENT BALANCE");
    paymentTokens[pTIndex].transferFrom(address(this), owner(), amount);
  }

  /**
   * @dev Computes the next vesting schedule identifier for a given holder address.
   */
  function computeNextVestingScheduleIdForHolder(address holder) public view returns (bytes32) {
    return computeVestingScheduleIdForAddressAndIndex(holder, holdersVestingCount[holder]);
  }

  /**
   * @dev Computes the releasable amount of tokens for a vesting schedule.
   * @return the amount of releasable tokens
   */
  function _computeReleasableAmount(VestingSchedule memory vestingSchedule) internal view returns (uint256) {
    uint256 currentTime = getCurrentTime();
    if ((currentTime < vestingSchedule.cliff) || vestingSchedule.revoked == true) {
      return 0;
    } else if (currentTime >= vestingSchedule.start.add(vestingSchedule.duration)) {
      return vestingSchedule.amountTotal.sub(vestingSchedule.released);
    } else {
      uint256 timeFromStart = currentTime.sub(vestingSchedule.start);
      uint256 secondsPerSlice = vestingSchedule.slicePeriodSeconds;
      uint256 vestedSlicePeriods = timeFromStart.div(secondsPerSlice);
      uint256 vestedSeconds = vestedSlicePeriods.mul(secondsPerSlice);
      uint256 vestedAmount = vestingSchedule.amountTotal.mul(vestedSeconds).div(vestingSchedule.duration);
      vestedAmount = vestedAmount.sub(vestingSchedule.released);
      return vestedAmount;
    }
  }

  /**
   * @notice Returns the vesting schedule information for a given holder and index.
   * @return the vesting schedule structure information
   */
  function getVestingScheduleByAddressAndIndex(address holder, uint256 index) external view returns (VestingSchedule memory) {
    return getVestingSchedule(computeVestingScheduleIdForAddressAndIndex(holder, index));
  }

  /**
   * @notice Returns the vesting schedule information for a given identifier.
   * @return the vesting schedule structure information
   */
  function getVestingSchedule(bytes32 vestingScheduleId) public view returns (VestingSchedule memory) {
    return vestingSchedules[vestingScheduleId];
  }

  /**
   * @dev Computes the vesting schedule identifier for an address and an index.
   */
  function computeVestingScheduleIdForAddressAndIndex(address holder, uint256 index) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(holder, index));
  }
}