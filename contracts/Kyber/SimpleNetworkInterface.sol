pragma solidity ^0.4.25;


import "./ERC20Interface.sol";


/// @title simple interface for Kyber Network 
interface SimpleNetworkInterface {
    function swapTokenToToken(ERC20Interface src, uint srcAmount, ERC20Interface dest, uint minConversionRate) public returns(uint);
    function swapEtherToToken(ERC20Interface token, uint minConversionRate) public payable returns(uint);
    function swapTokenToEther(ERC20Interface token, uint srcAmount, uint minConversionRate) public returns(uint);
}
