pragma solidity ^0.4.21;

import "zeppelin-solidity/contracts/token/ERC20/StandardToken.sol";

contract MediarToken is StandardToken {

    string public constant name = "MEDIAR TOKEN";
    string public constant symbol = "MEDIAR";
    uint8 public constant decimals = 18;

    uint256 public constant INITIAL_SUPPLY = 200000000 * (10 ** uint256(decimals));

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    function MediarToken() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
}