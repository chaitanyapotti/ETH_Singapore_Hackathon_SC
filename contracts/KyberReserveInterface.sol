pragma solidity ^0.4.25;


import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";


/// @title Kyber Reserve contract
interface KyberReserveInterface {

    function trade(
        ERC20Detailed srcToken,
        uint srcAmount,
        ERC20Detailed destToken,
        address destAddress,
        uint conversionRate,
        bool validate
    )
        public
        payable
        returns(bool);

    function getConversionRate(ERC20Detailed src, ERC20Detailed dest, uint srcQty, uint blockNumber) public view returns(uint);
}
