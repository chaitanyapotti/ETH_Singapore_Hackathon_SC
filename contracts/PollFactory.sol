pragma solidity ^0.4.25;

import "./Treasury.sol";
import "./Poll/UnBoundPoll.sol";


contract PollFactory is Treasury, KyberReserveInterface, Withdrawable, Utils {
    
    address public killPollAddress;
    address public tapPoll;
    mapping(address => bool) public pollAddresses;
    uint public killAcceptancePercent;
    uint public tapAcceptancePercent;
    uint public capPercent;
    uint public splineHeightAtPivot;
    uint public withdrawnTillNow;

    //Kyber
    address public kyberNetwork;
    bool public tradeEnabled;
    ConversionRatesInterface public conversionRatesContract;
    SanityRatesInterface public sanityRatesContract;
    ERC20Interface constant internal ETH_TOKEN_ADDRESS = ERC20Interface(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    event RefundStarted();
    event Withdraw(uint amountWei);
    event TapIncreased(uint currentTap, address contractAddress);
    event TapPollCreated(address tapPollAddress);

    //Kyber
    event DepositToken(ERC20Interface token, uint amount);

    constructor(address _erc20Token, address _teamAddress, uint _initialTap, uint _capPercent, 
    uint _killAcceptancePercent, uint _tapAcceptancePercent, uint _tapIncrementFactor, address _pollDeployer, 
    address _kyberNetwork, ConversionRatesInterface _ratesContract, address _daiAddress)
        public Treasury(_erc20Token, _teamAddress, _initialTap, _tapIncrementFactor, _pollDeployer, _daiAddress) {
            //check for cap maybe
            // cap is 10^2 multiplied to actual percentage - already in poll
            require(_killAcceptancePercent <= 80, "Kill Acceptance should be less than 80 %");
            require(_tapAcceptancePercent >= 50, "At least 50% must accept tap increment");
            capPercent = _capPercent;
            killAcceptancePercent = _killAcceptancePercent;
            tapAcceptancePercent = _tapAcceptancePercent;
            tapIncrementFactor = _tapIncrementFactor;
            kyberNetwork = _kyberNetwork;
            conversionRatesContract = _ratesContract;
        }
    
    function() public payable {
        emit DepositToken(ETH_TOKEN_ADDRESS, msg.value);
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
        tradeEnabled = false;
        emit TradeEnabled(false);
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
        tradeEnabled = true;
        emit TradeEnabled(true);
    }

    function withdrawAmount(uint _amount) external onlyOwner onlyDuringGovernance {
        bool canKillApp =  canKill();
        require(!canKillApp, "cannot withdraw now");
        uint contractEthBalance = address(this).balance;
        uint withdrawableAmount;
        uint tokensToSend;
        uint ethEqOfDai;
        ERC20Interface token = ERC20Interface(daiAddress);
        if (_amount <= contractEthBalance) {
            splineHeightAtPivot = SafeMath.add(splineHeightAtPivot, SafeMath.mul(SafeMath.sub(now, 
                    pivotTime), currentTap));
            require(_amount <= splineHeightAtPivot - withdrawnTillNow, "Not allowed");
            withdrawableAmount = _amount;
        } else {
            uint daiBalance = token.balanceOf(address(this));
            uint ethRate;
            ethEqOfDai = SafeMath.sub(_amount, contractEthBalance);
            (ethRate, ) = KyberNetworkProxy(kyberNetwork).getExpectedRate(ETH_TOKEN_ADDRESS, 
            ERC20Interface(daiAddress), ethEqOfDai);
            uint daiAsEthValue = SafeMath.mul(daiBalance, ethRate);
            tokensToSend = SafeMath.div(ethEqOfDai, ethRate);
            bool canSend;
            if (_amount <= SafeMath.add(contractEthBalance, daiAsEthValue)) {
                withdrawableAmount = contractEthBalance;
                canSend = true;
            }
        }
        if (withdrawableAmount >= 0) {
            pivotTime = now;
            withdrawnTillNow = SafeMath.add(withdrawnTillNow, SafeMath.add(withdrawableAmount, ethEqOfDai));
            if (canSend) require(token.transfer(msg.sender, tokensToSend), "Transfer unsuccessful");
            if (withdrawableAmount > 0) teamAddress.transfer(withdrawableAmount);
            emit Withdraw(withdrawableAmount);
        }
    }

    function isPollAddress(address _address) external view returns (bool) {
        return pollAddresses[_address];
    }

    event TradeExecute(
        address indexed origin,
        address src,
        uint srcAmount,
        address destToken,
        uint destAmount,
        address destAddress
    );

    function trade(
        ERC20Interface srcToken,
        uint srcAmount,
        ERC20Interface destToken,
        address destAddress,
        uint conversionRate,
        bool validate
    )
        public
        payable
        returns(bool)
    {
        require(tradeEnabled);
        require(msg.sender == kyberNetwork);

        require(doTrade(srcToken, srcAmount, destToken, destAddress, conversionRate, validate));

        return true;
    }

    event TradeEnabled(bool enable);

    function enableTrade() public onlyAdmin returns(bool) {
        tradeEnabled = true;
        emit TradeEnabled(true);

        return true;
    }

    function disableTrade() public onlyAlerter returns(bool) {
        tradeEnabled = false;
        emit TradeEnabled(false);

        return true;
    }

    event SetContractAddresses(address network, address rate, address sanity);

    function setContracts(
        address _kyberNetwork,
        ConversionRatesInterface _conversionRates,
        SanityRatesInterface _sanityRates
    )
        public
        onlyAdmin
    {
        require(_kyberNetwork != address(0));
        require(_conversionRates != address(0));

        kyberNetwork = _kyberNetwork;
        conversionRatesContract = _conversionRates;
        sanityRatesContract = _sanityRates;

        emit SetContractAddresses(kyberNetwork, conversionRatesContract, sanityRatesContract);
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

    function getBalance(ERC20Interface token) public view returns(uint) {
        if (token == ETH_TOKEN_ADDRESS)
            return this.balance;
        else {
            address wallet = address(this);
            return token.balanceOf(wallet);
        }
    }

    function getDestQty(ERC20Interface src, ERC20Interface dest, uint srcQty, uint rate) public view returns(uint) {
        uint dstDecimals = getDecimals(dest);
        uint srcDecimals = getDecimals(src);

        return calcDstQty(srcQty, srcDecimals, dstDecimals, rate);
    }

    function getSrcQty(ERC20Interface src, ERC20Interface dest, uint dstQty, uint rate) public view returns(uint) {
        uint dstDecimals = getDecimals(dest);
        uint srcDecimals = getDecimals(src);

        return calcSrcQty(dstQty, srcDecimals, dstDecimals, rate);
    }

    function getConversionRate(ERC20Interface src, ERC20Interface dest, uint srcQty, uint blockNumber) 
        public view returns(uint) {
            ERC20Interface token;
            bool  isBuy;

            if (!tradeEnabled) return 0;

            if (ETH_TOKEN_ADDRESS == src) {
                isBuy = true;
                token = dest;
            } else if (ETH_TOKEN_ADDRESS == dest) {
                isBuy = false;
                token = src;
            } else {
                return 0; // pair is not listed
            }

            uint rate = conversionRatesContract.getRate(token, blockNumber, isBuy, srcQty);
            uint destQty = getDestQty(src, dest, srcQty, rate);

            if (getBalance(dest) < destQty) return 0;

            if (sanityRatesContract != address(0)) {
                uint sanityRate = sanityRatesContract.getSanityRate(src, dest);
                if (rate > sanityRate) return 0;
            }

            return rate;
        }

    /// @dev do a trade
    /// @param srcToken Src token
    /// @param srcAmount Amount of src token
    /// @param destToken Destination token
    /// @param destAddress Destination address to send tokens to
    /// @param validate If true, additional validations are applicable
    /// @return true iff trade is successful
    function doTrade(
        ERC20Interface srcToken,
        uint srcAmount,
        ERC20Interface destToken,
        address destAddress,
        uint conversionRate,
        bool validate
    )
        internal
        returns(bool)
    {
        // can skip validation if done at kyber network level
        if (validate) {
            require(conversionRate > 0);
            if (srcToken == ETH_TOKEN_ADDRESS)
                require(msg.value == srcAmount);
            else
                require(msg.value == 0);
        }

        uint destAmount = getDestQty(srcToken, destToken, srcAmount, conversionRate);
        // sanity check
        require(destAmount > 0);

        // add to imbalance
        ERC20Interface token;
        int tradeAmount;
        if (srcToken == ETH_TOKEN_ADDRESS) {
            tradeAmount = int(destAmount);
            token = destToken;
        } else {
            tradeAmount = -1 * int(srcAmount);
            token = srcToken;
        }

        conversionRatesContract.recordImbalance(
            token,
            tradeAmount,
            0,
            block.number
        );

        // collect src tokens
        if (srcToken != ETH_TOKEN_ADDRESS) {
            require(srcToken.transferFrom(msg.sender, address(this), srcAmount));
        }

        // send dest tokens
        if (destToken == ETH_TOKEN_ADDRESS) {
            destAddress.transfer(destAmount);
        } else {
            require(destToken.transferFrom(address(this), destAddress, destAmount));
        }

        emit TradeExecute(msg.sender, srcToken, srcAmount, destToken, destAmount, destAddress);

        return true;
    }
}