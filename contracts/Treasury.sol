pragma solidity ^0.4.25;

import "./Interfaces/IDaicoToken.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "./PollDeployer.sol";


contract Treasury is Ownable {
    enum TreasuryState {
        CrowdSale,
        CrowdSaleRefund,
        Governance,
        Killed
    }

    uint public initialTap; //= 14844355; //wei/sec corresponds to approx 100 ether/month
    uint public currentTap; //wei/sec
    TreasuryState public state;
    IDaicoToken public erc20Token;
    PollDeployer public pollDeployer;
    address public crowdSaleAddress;
    address public teamAddress;
    uint public pivotTime;
    uint public totalEtherRaised;
    uint public tapIncrementFactor; // = 150;

    event RefundSent(address tokenHolder, uint256 amountWei, uint256 tokenAmount);
    event DaicoRefunded();
    
    constructor(address _erc20Token, address _teamAddress, uint _initialTap, uint _tapIncrementFactor, 
        address _pollDeployer) public {
        erc20Token = IDaicoToken(_erc20Token);
        teamAddress = _teamAddress;
        initialTap = _initialTap;
        tapIncrementFactor = _tapIncrementFactor;
        pollDeployer = PollDeployer(_pollDeployer);
    }

    modifier onlyCrowdSale() {
        require(msg.sender == crowdSaleAddress, "Not crowdsale address");
        _;
    }

    modifier onlyDuringCrowdSale() {
        require(state == TreasuryState.CrowdSale, "Not crowdsale phase");
        _;
    }

    modifier onlyDuringCrowdSaleRefund() {
        require(state == TreasuryState.CrowdSaleRefund, "Not crowdsale refund phase");
        _;
    }

    modifier onlyDuringGovernance() {
        require(state == TreasuryState.Governance, "Not Governance phase");
        _;
    }

    modifier onlyWhenKilled() {
        require(state == TreasuryState.Killed, "Not yet killed phase");
        _;
    }

    function setCrowdSaleAddress(address _crowdSaleAddress) external onlyOwner {
        require(crowdSaleAddress == address(0));
        crowdSaleAddress = _crowdSaleAddress;
    }

    function onR1Start() external onlyCrowdSale {
        state = TreasuryState.CrowdSale;
    }

    function onCrowdSaleR1End(uint _amount) external;

    function enableCrowdsaleRefund() external onlyCrowdSale onlyDuringCrowdSale {
        state = TreasuryState.CrowdSaleRefund;
        emit DaicoRefunded();
    }

    function refundBySoftcapFail() external onlyDuringCrowdSaleRefund {
        refundContributor(msg.sender);
    }

    function processContribution() external payable {
        require(state == TreasuryState.CrowdSale || state == TreasuryState.Governance, "Not accepting contributions");
        totalEtherRaised = SafeMath.add(totalEtherRaised, msg.value);
    }

    function refundByKill() public onlyWhenKilled {
        refundContributor(msg.sender);
    }

    function refundContributor(address _contributor) internal {
        uint tokenBalance = erc20Token.balanceOf(_contributor);
        require(tokenBalance > 0, "Zero token balance");
        uint refundAmount = SafeMath.div(SafeMath.mul(tokenBalance, address(this).balance), erc20Token.totalSupply());
        require(refundAmount > 0, "No refund amount available");
        erc20Token.burnFrom(_contributor, tokenBalance);
        _contributor.transfer(refundAmount);
        emit RefundSent(_contributor, refundAmount, tokenBalance);
    }
}