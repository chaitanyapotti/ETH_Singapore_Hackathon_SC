pragma solidity ^0.4.25;


import "openzeppelin-solidity/contracts/token/ERC20/ERC20Detailed.sol";


interface ConversionRatesInterface {

    function recordImbalance(
        ERC20Detailed token,
        int buyAmount,
        uint rateUpdateBlock,
        uint currentBlock
    )
        public;

    function getRate(ERC20Detailed token, uint currentBlockNumber, bool buy, uint qty) public view returns(uint);
}
