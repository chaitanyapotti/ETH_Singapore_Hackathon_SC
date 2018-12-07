pragma solidity ^0.4.25;

import "./Treasury.sol";
import "./Poll/UnBoundPoll.sol";
import "./Interfaces/KyberNetworkProxyInterface.sol";


contract PollFactory is Treasury {
    
    address public killPollAddress;
    address public tapPoll;
    mapping(address => bool) public pollAddresses;

    uint public killAcceptancePercent;
    uint public tapAcceptancePercent;
    uint public capPercent;
    uint public splineHeightAtPivot;
    uint public withdrawnTillNow;

    event RefundStarted();
    event Withdraw(uint amountWei);
    event TapIncreased(uint amountWei, address contractAddress);
    event TapPollCreated(address tapPollAddress);

    constructor(address _erc20Token, address _teamAddress, uint _initialTap, uint _capPercent, 
    uint _killAcceptancePercent, uint _tapAcceptancePercent, uint _tapIncrementFactor, address _pollDeployer)
        public Treasury(_erc20Token, _teamAddress, _initialTap, _tapIncrementFactor, _pollDeployer) {
            //check for cap maybe
            // cap is 10^2 multiplied to actual percentage - already in poll
            require(_killAcceptancePercent <= 80, "Kill Acceptance should be less than 80 %");
            require(_tapAcceptancePercent >= 50, "At least 50% must accept tap increment");
            capPercent = _capPercent;
            killAcceptancePercent = _killAcceptancePercent;
            tapAcceptancePercent = _tapAcceptancePercent;
            tapIncrementFactor = _tapIncrementFactor;
        }

    function createKillPoll() external {
        require(killPollAddress == address(0), "kill poll is already deployed");
        killPollAddress = pollDeployer.deployUnBoundPoll(address(0), "Yes", erc20Token, capPercent, 
        "DAICO", "Kill", "Token Proportional Capped Bound", now + 1, 0, address(this));
        pollAddresses[killPollAddress] = true;
    }

    function executeKill() external {
        bool canKillApp = canKill();
        require(canKillApp, "Cannot Kill Now");
        state = TreasuryState.Killed;
        emit RefundStarted();
    }

    function createTapIncrementPoll() external onlyOwner onlyDuringGovernance {        
        require(tapPoll == 0, "Tap Increment poll already exists");
        tapPoll = pollDeployer.deployUnBoundPoll(address(0), "yes", erc20Token, capPercent,
        "DAICO", "Tap Increment Poll", "Token Proportional Capped", now + 1, 0, address(this));
        pollAddresses[tapPoll] = true;
        emit TapPollCreated(tapPoll);
    }

    function increaseTap() external onlyOwner onlyDuringGovernance {
        bool canIncrease = canIncreaseTap();
        require(canIncrease, "Can't increase tap now");
        splineHeightAtPivot = SafeMath.add(splineHeightAtPivot, SafeMath.mul(SafeMath.sub(now, 
            pivotTime), currentTap));
        pivotTime = now;
        currentTap = SafeMath.div(SafeMath.mul(tapIncrementFactor, currentTap), 100);
        UnBoundPoll instance = UnBoundPoll(tapPoll);
        instance.endPoll();
        emit TapIncreased(currentTap, tapPoll);
        tapPoll = address(0);
    }

    function onCrowdSaleR1End() external onlyCrowdSale {
        state = TreasuryState.Governance;
        splineHeightAtPivot = 0;
        pivotTime = now;
        currentTap = initialTap;
    }

    function withdrawAmount(uint _amount) external onlyOwner onlyDuringGovernance {
        bool canKillApp =  canKill();
        require(!canKillApp, "cannot withdraw now");
        require(_amount < address(this).balance, "Insufficient funds");
        splineHeightAtPivot = SafeMath.add(splineHeightAtPivot, SafeMath.mul(SafeMath.sub(now, 
                pivotTime), currentTap));
        require(_amount <= splineHeightAtPivot - withdrawnTillNow, "Not allowed");
        pivotTime = now;
        splineHeightAtPivot = SafeMath.sub(splineHeightAtPivot, _amount);
        withdrawnTillNow += _amount;    
        teamAddress.transfer(_amount);
        emit Withdraw(_amount);
    }

    function isPollAddress(address _address) external view returns (bool) {
        return pollAddresses[_address];
    }

    function canIncreaseTap() public view returns (bool) {
        require(tapPoll != address(0), "No tap poll exists yet");
        UnBoundPoll instance = UnBoundPoll(tapPoll);
        uint consensus = SafeMath.div(instance.getVoteTally(0), erc20Token.totalSupply());
        bool canKillApp = canKill();
        return (consensus >= tapAcceptancePercent && !canKillApp);
    }

    function canKill() public view returns (bool) {
        UnBoundPoll currentKillPoll = UnBoundPoll(killPollAddress);
        uint consensus = SafeMath.div(currentKillPoll.getVoteTally(0), erc20Token.totalSupply());
        return consensus >= killAcceptancePercent;
    }
}