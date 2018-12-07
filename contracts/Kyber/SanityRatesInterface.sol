pragma solidity ^0.4.25;


import "./ERC20Interface.sol";


interface SanityRatesInterface {
    function getSanityRate(ERC20Interface src, ERC20Interface dest) public view returns(uint);
}
