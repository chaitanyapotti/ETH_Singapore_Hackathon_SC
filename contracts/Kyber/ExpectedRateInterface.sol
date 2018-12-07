pragma solidity ^0.4.25;


import "./ERC20Interface.sol";

interface ExpectedRateInterface {
    function getExpectedRate(ERC20Interface src, ERC20Interface dest, uint srcQty) public view
        returns (uint expectedRate, uint slippageRate);
}
