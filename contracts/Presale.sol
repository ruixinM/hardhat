//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IGoldToken {
    function mint(address to, uint256 amount) external;
}

contract Presale is Ownable, ReentrancyGuard {
    uint256 public userWithdrawTime;
    //uint256 public perMaxBuyUsdt = 100 * 10 ** 18;
    uint256 public perMaxBuyUsdt = 1 * 10 ** 17;
    address private teamAddress;
    address public saleToken;
    address public usdtToken;
    address public goldTokenAddress;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public userBuyTotalUsdt;
    mapping(address => uint256) public rewardBalances;
    mapping(address => address) public reffers;
    mapping(address => uint256) public refferNumber;
    mapping(address => uint256) public teamRefferNumber;
    mapping(address => bool) public firstIdo;
    uint256 public totalIdoUSDT;
    uint256 public totalIdoUser;
    uint256 public totalSale;
    //uint256 public inviteMin = 10;
    uint256 public inviteMin = 5;
    //uint256 public maxSale = 350000000 * 10 ** 18;
    uint256 public maxSale = 80000 * 10 ** 18;
    bool public isCloseSale;

    uint256[] public rewardLevel = [300, 200, 100, 50, 50, 30, 30, 20, 20, 10];

    struct PresaleInfo {
        uint256 startTime;
        uint256 endTime;
        uint256 price;
    }

    PresaleInfo public presaleInfo;

    constructor(address _saleToken, address _usdtToken, address _goldTokenAddress, uint256 _userWithdrawTime) public {
        saleToken = _saleToken;
        usdtToken = _usdtToken;
        goldTokenAddress = _goldTokenAddress;
        userWithdrawTime = _userWithdrawTime;
        teamAddress = msg.sender;
    }

    function createPreSale(PresaleInfo calldata _presaleInfo) public onlyOwner {
        presaleInfo = _presaleInfo;
    }

    function sale() public nonReentrant {
        require(!isCloseSale, "Presale close");
        require(reffers[msg.sender] != address(0), "Not bind parent inviter");

        require(block.timestamp >= presaleInfo.startTime);
        require(block.timestamp <= presaleInfo.endTime);
        if(refferNumber[msg.sender] >= inviteMin) {
            require(userBuyTotalUsdt[msg.sender] < 3*perMaxBuyUsdt, "Over max buy amount");
        } else {
            require(userBuyTotalUsdt[msg.sender] < perMaxBuyUsdt, "Over max buy amount");
        }

        uint256 getTokenNum = perMaxBuyUsdt * 10 ** 18 / presaleInfo.price;
        IERC20(usdtToken).transferFrom(msg.sender, address(this), perMaxBuyUsdt);
        balances[msg.sender] += getTokenNum;
        userBuyTotalUsdt[msg.sender] += perMaxBuyUsdt;
        totalSale += getTokenNum;
        totalIdoUSDT += perMaxBuyUsdt;

        address parent = reffers[msg.sender];
        for(uint256 i = 0; i < rewardLevel.length; i++) {
            if(parent == address(0)) break;
            uint256 reward = 0;
            reward = getTokenNum * rewardLevel[i]/10000;
            rewardBalances[parent] += reward;
            totalSale += reward;

            if(!firstIdo[msg.sender] && i > 0) {
                teamRefferNumber[parent] += 1;
            }

            parent = reffers[parent];
        }

        if(!firstIdo[msg.sender]) {
            totalIdoUser++;
            firstIdo[msg.sender] = true;
            parent = reffers[msg.sender];
            if (parent != address(0)) {
                refferNumber[parent] += 1;
                IGoldToken(goldTokenAddress).mint(parent, 10 * 10 ** 18);
            }

            IGoldToken(goldTokenAddress).mint(msg.sender, 10 * 10 ** 18);
        }

        isCloseSale = totalSale >= maxSale;
    }

    function getCanIdoAmount(address owner) public view returns (uint256) {
        uint256 userIdoAmount = userBuyTotalUsdt[owner];
        if(refferNumber[owner] >= inviteMin) {
            return 3*perMaxBuyUsdt - userIdoAmount;
        } else {
            return perMaxBuyUsdt - userIdoAmount;
        }
    }

    function bindReffer(address parent) public {
        require(reffers[msg.sender] == address(0), "Has bind invite");
        require(parent == teamAddress || userBuyTotalUsdt[parent] > 0, "Bind address not is a ido user");
        reffers[msg.sender] = parent;
    }

    function userBalance(address userAddress) public view returns (uint256) {
        uint256 bal = balances[userAddress];
        return bal;
    }

    function userRewardBalance(address userAddress) public view returns (uint256) {
        uint256 bal = rewardBalances[userAddress];
        return bal;
    }

    function userWithdraw() public nonReentrant {
        require(block.timestamp > userWithdrawTime);
        uint256 bal = balances[msg.sender] + rewardBalances[msg.sender];
        require(bal > 0, "balance is 0");

        balances[msg.sender] = 0;
        rewardBalances[msg.sender] = 0;
        IERC20(saleToken).transfer(msg.sender, bal);
    }

    function teamWithdraw(address addr) public onlyOwner {
        uint bal = IERC20(addr).balanceOf(address(this));
        IERC20(addr).transfer(teamAddress, bal);
    }

    function setUserWithdrawTime(uint256 _userWithdrawTime) public onlyOwner {
        userWithdrawTime = _userWithdrawTime;
    }

    function setInviteMin(uint256 _inviteMin) public onlyOwner {
        inviteMin = _inviteMin;
    }

    function setPerMaxBuyUsdt(uint256 _perMaxBuyUsdt) public onlyOwner {
        perMaxBuyUsdt = _perMaxBuyUsdt;
    }
}