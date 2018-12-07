pragma solidity ^0.4.25;


import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";
import "./Utils.sol";
import "./SanityRatesInterface.sol";
import "./Withdrawable.sol";


contract SanityRates is SanityRatesInterface, Withdrawable, Utils {
    mapping(address=>uint) public tokenRate;
    mapping(address=>uint) public reasonableDiffInBps;

    constructor(address _admin) public {
        require(_admin != address(0));
        admin = _admin;
    }

    function setReasonableDiff(IERC20[] srcs, uint[] diff) public onlyAdmin {
        require(srcs.length == diff.length);
        for (uint i = 0; i < srcs.length; i++) {
            require(diff[i] <= 100 * 100);
            reasonableDiffInBps[srcs[i]] = diff[i];
        }
    }

    function setSanityRates(IERC20[] srcs, uint[] rates) public onlyOperator {
        require(srcs.length == rates.length);

        for (uint i = 0; i < srcs.length; i++) {
            require(rates[i] <= MAX_RATE);
            tokenRate[srcs[i]] = rates[i];
        }
    }

    function getSanityRate(IERC20 src, IERC20 dest) public view returns(uint) {
        if (src != ETH_TOKEN_ADDRESS && dest != ETH_TOKEN_ADDRESS) return 0;

        uint rate;
        address token;
        if (src == ETH_TOKEN_ADDRESS) {
            rate = (PRECISION*PRECISION)/tokenRate[dest];
            token = dest;
        } else {
            rate = tokenRate[src];
            token = src;
        }

        return rate * (10000 + reasonableDiffInBps[token])/10000;
    }
}
