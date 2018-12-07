pragma solidity ^0.4.25;

import "electusvoting/contracts/Token/FreezableToken.sol";
import "../Interfaces/IPollAddresses.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";


contract DaicoToken is FreezableToken, Ownable {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint public capTokenAmount;
    address public crowdSaleAddress;
    IPollAddresses public pollMember;

    constructor(string _name, string _symbol, uint _totalMintableSupply, uint _capPercent) public {
        name = _name;
        symbol = _symbol;
        totalMintableSupply = _totalMintableSupply;
        capTokenAmount = SafeMath.div(SafeMath.mul(_capPercent, _totalMintableSupply), 10000);
    }

    modifier onlyTreasury {
        require(msg.sender == address(pollMember), "Only treasury can burn");
        _;
    }

    modifier onlyCrowdSale() {
        require(msg.sender == crowdSaleAddress, "Only crowdsale can mint");
        _;
    }

    modifier isPollAddress() {
        require(pollMember.isPollAddress(msg.sender), "Not a poll, cannot freeze/ unfreeze");
        _;
    }

    function setTreasuryAddress(address _treasuryAddress) external onlyOwner {
        require(address(pollMember) == address(0));
        pollMember = IPollAddresses(_treasuryAddress);
    }

    function setCrowdSaleAddress(address _crowdSaleAddress) external onlyOwner {
        require(crowdSaleAddress == address(0));
        crowdSaleAddress = _crowdSaleAddress;
    }

    function burnFrom(address _from, uint256 _value) external onlyTreasury {
        super._burn(_from, _value);
    }

    function freezeAccount(address _target) public isPollAddress {
        super.freezeAccount(_target);
    }

    function unFreezeAccount(address _target) public isPollAddress {
        super.unFreezeAccount(_target);
    }

    function mint(address _to, uint256 _amount) public onlyCrowdSale returns (bool) {
        return super.mint(_to, _amount);
    }

    function finishMinting() public onlyCrowdSale returns (bool) {
        return super.finishMinting();
    }
}