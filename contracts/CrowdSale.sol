pragma solidity ^0.4.25;

import "./Interfaces/IDaicoToken.sol";
import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./Interfaces/ICrowdSaleTreasury.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol"; //need to check if necessary


contract CrowdSale is Ownable {

    struct RoundData {
        uint tokenCount;
        uint tokenRate; //rate is in tokens/wei
        uint totalTokensSold;
        uint endTime;
        uint startTime;
    }

    RoundData public roundDetails;
    IDaicoToken public erc20Token;
    ICrowdSaleTreasury public treasury;

    bool private paused;
    uint public etherMinContrib;
    uint public etherMaxContrib;
    mapping(address => uint) public userContributonDetails;

    event LogContribution(address contributor, uint etherAmount, uint tokenAmount);

    constructor (uint _etherMinContrib, uint _etherMaxContrib, uint _endTime, uint _startTime,
        uint _tokenCount, uint _tokenRate, address _treasuryAddress, address _erc20TokenAddress) public {
        
        erc20Token = IDaicoToken(_erc20TokenAddress);
        treasury = ICrowdSaleTreasury(_treasuryAddress);

        etherMinContrib = _etherMinContrib;
        etherMaxContrib = _etherMaxContrib;

        roundDetails = RoundData({
            tokenCount: _tokenCount, tokenRate: _tokenRate, endTime: _endTime, totalTokensSold: 0, 
            startTime: _startTime
        });
        paused = true;
    }

    modifier checkContribution() {
        require(isValidContribution(), "Not a valid contribution");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Crowdsale is paused");
        _;
    }

    function () public payable whenNotPaused {
        processContribution(msg.sender, msg.value);
    }

    function finalizeDaico() public {
        RoundData storage roundInfo = roundDetails;
        if (now >= roundInfo.endTime && roundInfo.totalTokensSold < roundInfo.tokenCount) {
            paused = true;
            treasury.enableCrowdsaleRefund();
        }
    }

    function startNewRound() public onlyOwner {
        require(paused, "Crowdsale must be paused");
        require(now > roundDetails.startTime, "Can't start yet");
        require(now < roundDetails.endTime, "Time has elapsed");
        treasury.onR1Start();
        paused = false;
    }

    function isValidContribution() internal view returns (bool) {  
        uint userContrib = userContributonDetails[msg.sender];
        uint256 currentUserContribution = SafeMath.add(msg.value, userContrib);
        RoundData storage roundInfo = roundDetails;
        if ((msg.value >= etherMinContrib || SafeMath.add(SafeMath.mul(msg.value, roundInfo.tokenRate), 
        roundInfo.totalTokensSold) >= roundInfo.tokenCount) && ((currentUserContribution <= etherMaxContrib))) {
            return true;
        }
        return false;
    }
    
    function processContribution(address _contributor, uint256 _amount) internal checkContribution {
        RoundData storage roundInfo = roundDetails;
        require(now <= roundInfo.endTime, "First round has passed");
        uint tokensToGiveUser = SafeMath.mul(_amount, roundInfo.tokenRate);
        uint tempTotalTokens = SafeMath.add(tokensToGiveUser, roundInfo.totalTokensSold);
        
        uint weiSpent = 0;
        uint weiLeft = 0;
        uint totalTokensToSend = 0;
        if (tempTotalTokens < roundInfo.tokenCount) {
            weiSpent = _amount;
            totalTokensToSend = tokensToGiveUser;
            roundInfo.totalTokensSold = tempTotalTokens;
        } else {
            uint leftTokens = SafeMath.sub(roundInfo.tokenCount, roundInfo.totalTokensSold);
            weiSpent = SafeMath.div(leftTokens, roundInfo.tokenRate);
            roundInfo.totalTokensSold = roundInfo.tokenCount;
            totalTokensToSend = leftTokens;
            weiLeft = SafeMath.sub(_amount, weiSpent);            
            treasury.onCrowdSaleR1End();
            paused = true;
        }
        
        userContributonDetails[_contributor] = SafeMath.add(userContributonDetails[_contributor], weiSpent);
        
        processPayment(_contributor, weiSpent, totalTokensToSend);
        if (weiLeft > 0) {
            erc20Token.finishMinting();
            _contributor.transfer(weiLeft);
        }
    }

    function processPayment(address contributor, uint etherAmount, uint256 tokenAmount) internal {
        erc20Token.mint(contributor, tokenAmount, true);
        treasury.processContribution.value(etherAmount)();
        emit LogContribution(contributor, etherAmount, tokenAmount);
    }
}
