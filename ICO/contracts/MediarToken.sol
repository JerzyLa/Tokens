pragma solidity ^0.4.19;

import 'zeppelin-solidity/contracts/token/ERC20/StandardToken.sol';

contract MediarToken is StandardToken {
    string public name = "MEDIAR TOKEN";
    string public symbol = "MEDIAR";
    uint8 public decimals = 18;
}