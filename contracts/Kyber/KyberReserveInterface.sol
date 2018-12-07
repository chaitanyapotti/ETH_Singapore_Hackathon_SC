pragma solidity ^0.4.25;


import "./ERC20Interface.sol";

/// @title Kyber Reserve contract
interface KyberReserveInterface {

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
        returns(bool);

    function getConversionRate(ERC20Interface src, ERC20Interface dest, uint srcQty, uint blockNumber) public view returns(uint);
}
