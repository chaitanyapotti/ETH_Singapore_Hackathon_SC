pragma solidity ^0.4.25;


import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";


interface SanityRatesInterface {
    function getSanityRate(IERC20 src, IERC20 dest) public view returns(uint);
}
