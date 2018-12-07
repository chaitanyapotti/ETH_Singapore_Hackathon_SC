pragma solidity ^0.4.25;


import "./ERC20Interface.sol";


interface ConversionRatesInterface {

    function recordImbalance(
        ERC20Interface token,
        int buyAmount,
        uint rateUpdateBlock,
        uint currentBlock
    )
        public;

    function getRate(ERC20Interface token, uint currentBlockNumber, bool buy, uint qty) public view returns(uint);
}
