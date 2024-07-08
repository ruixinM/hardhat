// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Interface to interact with RJV contract
interface IRejuvenate {
    function mint(address to_, uint256 amount_) external;
}

contract Staking is Ownable, ReentrancyGuard {
    bool public paused;
    address internal _treasury;

    address public token;

    uint256 public rewardRate;
    uint256 internal _lastUpdateBlock;
    uint256 internal _rewardsPerToken;
    StakingData[] public data;

    mapping(address => uint256) internal _userRewardsPerToken;
    mapping(address => uint256) internal _rewards;

    uint256 public totalStaked;
    mapping(address => uint256) internal _balances;

    event Stake(address wallet, uint256 amount, uint256 staked);
    event Unstake(address wallet, uint256 amount, uint256 staked);

    constructor() {
        token = 0x2B60Bd0D80495DD27CE3F8610B4980E94056b30c;
        rewardRate = 0.02 ether;
        paused = false;
        _treasury = 0xFb08de74D3DC381d2130e8885BdaD4e558b24145;
        data.push(StakingData(block.number, 0));
    }

    function changeRewardsPerBlock(uint256 rewardRate_) external onlyOwner {
        rewardRate = rewardRate_;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return 0;
        }
        return
        _rewardsPerToken +
        ((rewardRate * (block.number - _lastUpdateBlock) * 1e18) / totalStaked);
    }

    function earned(address wallet_) public view returns (uint256) {
        return
        ((_balances[wallet_] *
        (rewardPerToken() - _userRewardsPerToken[wallet_])) / 1e18) +
        _rewards[wallet_];
    }

    modifier updateReward(address wallet_) {
        _rewardsPerToken = rewardPerToken();
        _lastUpdateBlock = block.number;

        _rewards[wallet_] = earned(wallet_);
        _userRewardsPerToken[wallet_] = _rewardsPerToken;
        _;
    }

    function stake(uint256 amount_)
    external
    payable
    nonReentrant
    notPaused
    updateReward(msg.sender)
    {
        totalStaked += amount_;
        _balances[msg.sender] += amount_;
        data.push(StakingData(block.number, totalStaked));
        IERC20(token).transferFrom(msg.sender, address(this), amount_);
        emit Stake(msg.sender, amount_, _balances[msg.sender]);
    }

    function unstake(uint256 amount_)
    external
    payable
    nonReentrant
    notPaused
    updateReward(msg.sender)
    {
        require(_balances[msg.sender] >= amount_, "Not enought staked");
        totalStaked -= amount_;
        _balances[msg.sender] -= amount_;
        data.push(StakingData(block.number, totalStaked));
        IERC20(token).transfer(msg.sender, amount_);
        emit Unstake(msg.sender, amount_, _balances[msg.sender]);
    }

    function claimRewards() external payable notPaused updateReward(msg.sender) {
        uint256 reward = _rewards[msg.sender];
        _rewards[msg.sender] = 0;
        IRejuvenate(token).mint(msg.sender, reward);
    }

    modifier paysFee(uint256 value_) {
        require(value_ >= 0.01 ether, "not enough fees");
        (bool sent, bytes memory callingData) = _treasury.call{ value: value_ }("");
        require(sent, "Failed to send BNB");
        _;
    }

    modifier notPaused() {
        require(!paused, "Contract is currently Paused!");
        _;
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    function inCaseTokensGetStuck(address token_) external onlyOwner {
        require(token_ != token, "!token");
        uint256 amount = IERC20(token_).balanceOf(address(this));
        IERC20(token_).transfer(msg.sender, amount);
    }
}

    struct StakingData {
        uint256 block;
        uint256 staked;
    }