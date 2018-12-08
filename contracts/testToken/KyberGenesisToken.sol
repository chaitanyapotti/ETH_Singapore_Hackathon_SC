pragma solidity ^0.4.25;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";


contract KyberGenesisToken is ERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string name, string symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _mint(msg.sender, 39485);
    }

    function name() public view returns(string) {
        return _name;
    }

    function symbol() public view returns(string) {
        return _symbol;
    }

    function decimals() public view returns(uint8) {
        return _decimals;
    }
}